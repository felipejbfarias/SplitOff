import Foundation
import SwiftData

enum CRUDErro: LocalizedError {
    case nomeVazio
    case precoNegativo
    case pagamentoNegativo
    case quantidadeInvalida
    case pessoaForaDoGrupo
    case participanteDuplicado
    case participanteForaDaComanda
    case itemSemDono
    case comandaInativa
    case comandaAtivaJaExiste
    case comandaNaoPodeFechar(total: Decimal, pago: Decimal)
    case fechamentoDiretoInvalido
    case comandaFechadaNaoPodeReativar
    case valorTransferenciaInvalido
    case transferenciaParaMesmaPessoa
    case pessoasEmGruposDiferentes
    case nomeReservado
    case voceImutavel
    case grupoVoceImutavel
    case pagamentoExcedeTotal(restante: Decimal)
    case grupoDuplicado
    case lugarDuplicado

    var errorDescription: String? {
        switch self {
        case .nomeVazio:
            return "O nome não pode ficar vazio."
        case .precoNegativo:
            return "O preço não pode ser negativo."
        case .pagamentoNegativo:
            return "O pagamento não pode ser negativo."
        case .quantidadeInvalida:
            return "A quantidade precisa ser maior que zero."
        case .pessoaForaDoGrupo:
            return "A pessoa precisa pertencer ao mesmo grupo da comanda."
        case .participanteDuplicado:
            return "Essa pessoa já participa da comanda."
        case .participanteForaDaComanda:
            return "Todos os donos do item precisam participar da comanda do pedido."
        case .itemSemDono:
            return "O item do pedido precisa ter pelo menos um dono."
        case .comandaInativa:
            return "Essa operação só pode ser feita em uma comanda ativa."
        case .comandaAtivaJaExiste:
            return "Já existe uma comanda ativa."
        case let .comandaNaoPodeFechar(total, pago):
            return "A comanda só pode ser fechada quando o total pago (\(pago)) for igual ao total da conta (\(total))."
        case .fechamentoDiretoInvalido:
            return "Para fechar uma comanda, use a regra de fechamento da comanda."
        case .comandaFechadaNaoPodeReativar:
            return "Uma comanda fechada não pode ser reativada."
        case .valorTransferenciaInvalido:
            return "O valor da transferência precisa ser maior que zero."
        case .transferenciaParaMesmaPessoa:
            return "A transferência precisa ter pessoas diferentes."
        case .pessoasEmGruposDiferentes:
            return "As duas pessoas precisam pertencer ao mesmo grupo."
        case .nomeReservado:
            return "O nome \"Você\" é reservado para o dono do app."
        case .voceImutavel:
            return "O \"Você\" não pode ser renomeado ou removido."
        case .grupoVoceImutavel:
            return "O grupo \"Você\" não pode ser renomeado ou removido."
        case let .pagamentoExcedeTotal(restante):
            return "O pagamento passa do total da comanda. Falta pagar \(restante.formatted(.currency(code: "BRL")))."
        case .grupoDuplicado:
            return "Já existe um grupo com esse nome."
        case .lugarDuplicado:
            return "Já existe um lugar com esse nome."
        }
    }
}

@MainActor
final class CRUD {
    // O dono do app: uma Pessoa "Você" própria por grupo (saldos isolados entre grupos)
    // e um grupo pessoal "Você" para as saídas sozinho. Identificados pelo nome, que é
    // reservado: ninguém mais pode se chamar assim, nem renomear/remover os originais.
    static let nomeVoce = "Você"

    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // Garante o grupo pessoal "Você" desde a primeira inicialização do app.
    func garantirGrupoVoce() throws {
        let grupos = try context.fetch(FetchDescriptor<Grupo>())
        guard !grupos.contains(where: { $0.nome == Self.nomeVoce }) else { return }

        let grupo = Grupo(nome: Self.nomeVoce)
        context.insert(grupo)
        voceDoGrupo(grupo)
        try salvar()
    }

    // Cria um grupo, já com o seu próprio "Você" dentro. Nomes não podem repetir.
    @discardableResult
    func criarGrupo(nome: String, foto: Data? = nil) throws -> Grupo {
        let nomeGrupo = try nomeValidado(nome)
        guard !ehNomeReservado(nomeGrupo) else { throw CRUDErro.nomeReservado }

        let grupos = try context.fetch(FetchDescriptor<Grupo>())
        guard !grupos.contains(where: { mesmoNome($0.nome, nomeGrupo) }) else {
            throw CRUDErro.grupoDuplicado
        }

        let grupo = Grupo(nome: nomeGrupo, foto: foto)
        context.insert(grupo)
        voceDoGrupo(grupo)
        try salvar()
        return grupo
    }

    // Cria uma pessoa já vinculada a um grupo. O "Você" nasce junto com o grupo, nunca por aqui.
    @discardableResult
    func criarPessoa(nome: String, grupo: Grupo, saldo: Decimal = 0) throws -> Pessoa {
        let nomePessoa = try nomeValidado(nome)
        guard !ehNomeReservado(nomePessoa) else { throw CRUDErro.nomeReservado }

        let pessoa = Pessoa(nome: nomePessoa, saldo: saldo, grupo: grupo)
        context.insert(pessoa)
        try salvar()
        return pessoa
    }

    // Cria um lugar já com um cardápio vazio associado. Nomes não podem repetir.
    @discardableResult
    func criarLugar(nome: String, nomeCardapio: String = "Cardápio") throws -> Restaurante {
        let nomeLugar = try nomeValidado(nome)

        let lugares = try context.fetch(FetchDescriptor<Restaurante>())
        guard !lugares.contains(where: { mesmoNome($0.nome, nomeLugar) }) else {
            throw CRUDErro.lugarDuplicado
        }

        let cardapio = Cardapio(nome: try nomeValidado(nomeCardapio))
        let restaurante = Restaurante(nome: nomeLugar, cardapio: cardapio)
        context.insert(restaurante)
        try salvar()
        return restaurante
    }

    // Cria um item dentro de um cardápio.
    @discardableResult
    func criarItem(nome: String, preco: Decimal, cardapio: Cardapio) throws -> Item {
        try validarPreco(preco)
        let item = Item(nome: try nomeValidado(nome), preco: preco, cardapio: cardapio)
        context.insert(item)
        try salvar()
        return item
    }

    @discardableResult
    func criarComanda(
        nome: String,
        grupo: Grupo,
        restaurante: Restaurante,
        cobraTaxaServico: Bool = true,
        valorCouvertPorPessoa: Decimal = 0,
        ativa: Bool = true
    ) throws -> Comanda {
        if ativa {
            try validarComandaAtivaUnica()
        }
        try validarPreco(valorCouvertPorPessoa)

        let comanda = Comanda(
            nome: try nomeValidado(nome),
            ativa: ativa,
            cobraTaxaServico: cobraTaxaServico,
            valorCouvertPorPessoa: valorCouvertPorPessoa,
            restaurante: restaurante,
            grupo: grupo
        )
        context.insert(comanda)

        // Você do grupo participa de toda comanda
        let voce = voceDoGrupo(grupo)
        let participante = ParticipanteComanda(pessoa: voce, comanda: comanda, nomePessoa: voce.nome)
        context.insert(participante)

        try salvar()
        return comanda
    }

    // Cria uma rodada de pedido dentro de uma comanda ativa.
    @discardableResult
    func criarPedido(comanda: Comanda) throws -> Pedido {
        try validarComandaAtiva(comanda)
        let numero = comanda.pedidos.count + 1
        let pedido = Pedido(numero: numero, comanda: comanda)
        context.insert(pedido)
        try salvar()
        return pedido
    }

    // Cria um item consumido em uma rodada de pedido.
    @discardableResult
    func criarItemPedido(
        nome: String,
        preco: Decimal,
        pedido: Pedido,
        donos: [ParticipanteComanda],
        itemCardapio: Item? = nil
    ) throws -> ItemPedido {
        try validarPreco(preco)
        try validarDonos(donos, para: pedido)

        let itemPedido = ItemPedido(
            nome: try nomeValidado(nome),
            preco: preco,
            donos: donos,
            itemCardapio: itemCardapio
        )
        itemPedido.pedido = pedido
        context.insert(itemPedido)
        try salvar()
        return itemPedido
    }

    // Cria um item consumido a partir do cardápio, multiplicando pelo total escolhido no picker.
    @discardableResult
    func criarItemPedido(
        itemCardapio: Item,
        quantidade: Int,
        pedido: Pedido,
        donos: [ParticipanteComanda]
    ) throws -> ItemPedido {
        guard quantidade > 0 else { throw CRUDErro.quantidadeInvalida }
        return try criarItemPedido(
            nome: itemCardapio.nome,
            preco: itemCardapio.preco * Decimal(quantidade),
            pedido: pedido,
            donos: donos,
            itemCardapio: itemCardapio
        )
    }

    // Adiciona uma pessoa como participante de uma comanda. Só funciona se a pessoa pertencer ao mesmo grupo da comanda e ainda não estiver nela.
    @discardableResult
    func adicionarParticipante(_ pessoa: Pessoa, a comanda: Comanda) throws -> ParticipanteComanda {
        try validarComandaAtiva(comanda)
        guard pessoa.grupo == comanda.grupo else { throw CRUDErro.pessoaForaDoGrupo }
        guard !comanda.participantes.contains(where: { $0.pessoa == pessoa }) else { throw CRUDErro.participanteDuplicado }

        let participante = ParticipanteComanda(pessoa: pessoa, comanda: comanda, nomePessoa: pessoa.nome)
        context.insert(participante)

        try salvar()
        return participante
    }

    // Soma mais um pagamento ao total já pago pelo participante na comanda.
    // A soma de todos os pagamentos nunca pode passar do total da conta.
    func registrarPagamento(_ valorPago: Decimal, para participante: ParticipanteComanda) throws {
        guard valorPago >= 0 else { throw CRUDErro.pagamentoNegativo }
        guard let comanda = participante.comanda else { throw CRUDErro.participanteForaDaComanda }
        try validarComandaAtiva(comanda)

        let restante = comanda.valorTotal - comanda.valorPago
        guard valorPago <= restante + Comanda.limiarFechamento else {
            throw CRUDErro.pagamentoExcedeTotal(restante: max(0, restante))
        }

        participante.valorPago += valorPago
        try salvar()
    }

    // Fecha a comanda quando a soma dos pagamentos cobre exatamente o total da conta.
    func fecharComanda(_ comanda: Comanda) throws {
        try validarComandaAtiva(comanda)
        guard comanda.podeFechar else {
            throw CRUDErro.comandaNaoPodeFechar(total: comanda.valorTotal, pago: comanda.valorPago)
        }

        for participante in comanda.participantes {
            guard let pessoa = participante.pessoa else { continue }
            pessoa.saldo += participante.valorPago - participante.contaAtual
        }

        comanda.ativa = false
        try salvar()
    }

    // Registra uma transferencia entre duas pessoas do mesmo grupo e ajusta seus saldos acumulados.
    @discardableResult
    func registrarTransferencia(
        valor: Decimal,
        de pagador: Pessoa,
        para recebedor: Pessoa,
        tipo: TipoTransferencia = .quitacao,
        observacao: String? = nil
    ) throws -> Transferencia {
        try validarTransferencia(valor: valor, de: pagador, para: recebedor)

        let transferencia = Transferencia(
            valor: valor,
            tipo: tipo,
            observacao: observacao,
            grupo: pagador.grupo,
            pagador: pagador,
            recebedor: recebedor
        )

        pagador.saldo += valor
        recebedor.saldo -= valor

        context.insert(transferencia)
        try salvar()
        return transferencia
    }

    // Atualiza os dados de um grupo. O grupo pessoal "Você" é imutável.
    func atualizarGrupo(_ grupo: Grupo, nome: String) throws {
        guard grupo.nome != Self.nomeVoce else { throw CRUDErro.grupoVoceImutavel }

        let novoNome = try nomeValidado(nome)
        guard !ehNomeReservado(novoNome) else { throw CRUDErro.nomeReservado }

        grupo.nome = novoNome
        try salvar()
    }

    // Atualiza os dados editáveis de uma pessoa. O "Você" é imutável e o saldo
    // é alterado apenas por comandas fechadas e transferências.
    func atualizarPessoa(_ pessoa: Pessoa, nome: String) throws {
        guard pessoa.nome != Self.nomeVoce else { throw CRUDErro.voceImutavel }

        let nomeValidado = try nomeValidado(nome)
        guard !ehNomeReservado(nomeValidado) else { throw CRUDErro.nomeReservado }

        pessoa.nome = nomeValidado

        for participacao in pessoa.participacoesComanda {
            participacao.nomePessoa = nomeValidado
        }

        try salvar()
    }

    // Atualiza nome e preço de um item do cardápio.
    func atualizarItem(_ item: Item, nome: String, preco: Decimal) throws {
        try validarPreco(preco)
        item.nome = try nomeValidado(nome)
        item.preco = preco
        try salvar()
    }

    // Atualiza nome de uma comanda ativa. Para fechar comanda, use fecharComanda(_:).
    func atualizarComanda(_ comanda: Comanda, nome: String, ativa: Bool) throws {
        if comanda.ativa {
            guard ativa else { throw CRUDErro.fechamentoDiretoInvalido }
        } else {
            guard !ativa else { throw CRUDErro.comandaFechadaNaoPodeReativar }
        }

        comanda.nome = try nomeValidado(nome)
        try salvar()
    }

    // Remove um grupo. Em cascata, apaga também suas pessoas e suas comandas.
    // O grupo Você não pode ser removido.
    func removerGrupo(_ grupo: Grupo) throws {
        guard grupo.nome != Self.nomeVoce else { throw CRUDErro.grupoVoceImutavel }
        context.delete(grupo)
        try salvar()
    }

    // Remove uma pessoa preservando participações e transferências históricas.
    // Você não pode ser removido.
    func removerPessoa(_ pessoa: Pessoa) throws {
        guard pessoa.nome != Self.nomeVoce else { throw CRUDErro.voceImutavel }
        context.delete(pessoa)
        try salvar()
    }

    // Remove um item do cardápio preservando os itens de pedidos históricos.
    func removerItem(_ item: Item) throws {
        context.delete(item)
        try salvar()
    }

    // Remove uma comanda do histórico. Em cascata, apaga participantes e pedidos.
    // Não altera saldos já fechados das pessoas.
    func removerComanda(_ comanda: Comanda) throws {
        context.delete(comanda)
        try salvar()
    }

    // Você do grupo
    @discardableResult
    private func voceDoGrupo(_ grupo: Grupo) -> Pessoa {
        if let voce = grupo.pessoas.first(where: { $0.nome == Self.nomeVoce }) {
            return voce
        }

        let voce = Pessoa(nome: Self.nomeVoce, grupo: grupo)
        context.insert(voce)
        return voce
    }

    // "você", "VOCÊ", "Voce"... todas as variações são reservadas.
    private func ehNomeReservado(_ nome: String) -> Bool {
        mesmoNome(nome, Self.nomeVoce)
    }

    // Compara nomes ignorando caixa e acentos ("mamute" == "Mamute").
    private func mesmoNome(_ um: String, _ outro: String) -> Bool {
        um.compare(outro, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
    }

    private func nomeValidado(_ nome: String) throws -> String {
        let nomeLimpo = nome.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nomeLimpo.isEmpty else { throw CRUDErro.nomeVazio }
        return nomeLimpo
    }

    private func validarPreco(_ preco: Decimal) throws {
        guard preco >= 0 else { throw CRUDErro.precoNegativo }
    }

    private func validarDonos(_ donos: [ParticipanteComanda], para pedido: Pedido) throws {
        guard !donos.isEmpty else { throw CRUDErro.itemSemDono }
        guard let comanda = pedido.comanda else { throw CRUDErro.participanteForaDaComanda }

        let donosInvalidos = donos.contains { dono in
            dono.comanda != comanda || !comanda.participantes.contains(where: { $0 == dono })
        }

        guard !donosInvalidos else { throw CRUDErro.participanteForaDaComanda }
    }

    private func validarComandaAtiva(_ comanda: Comanda) throws {
        guard comanda.ativa else { throw CRUDErro.comandaInativa }
    }

    private func validarTransferencia(valor: Decimal, de pagador: Pessoa, para recebedor: Pessoa) throws {
        guard valor > 0 else { throw CRUDErro.valorTransferenciaInvalido }
        guard pagador != recebedor else { throw CRUDErro.transferenciaParaMesmaPessoa }
        guard let grupo = pagador.grupo, grupo == recebedor.grupo else { throw CRUDErro.pessoasEmGruposDiferentes }
    }

    private func validarComandaAtivaUnica() throws {
        let comandas = try context.fetch(FetchDescriptor<Comanda>())
        guard !comandas.contains(where: { $0.ativa }) else { throw CRUDErro.comandaAtivaJaExiste }
    }

    // Persiste as mudanças pendentes no banco.
    private func salvar() throws {
        try context.save()
    }
}

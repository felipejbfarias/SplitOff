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
        }
    }
}

@MainActor
final class CRUD {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // Cria um grupo.
    @discardableResult
    func criarGrupo(nome: String, foto: Data? = nil) throws -> Grupo {
        let grupo = Grupo(nome: try nomeValidado(nome), foto: foto)
        context.insert(grupo)
        try salvar()
        return grupo
    }

    // Cria uma pessoa já vinculada a um grupo.
    @discardableResult
    func criarPessoa(nome: String, grupo: Grupo, saldo: Decimal = 0) throws -> Pessoa {
        let pessoa = Pessoa(nome: try nomeValidado(nome), saldo: saldo, grupo: grupo)
        context.insert(pessoa)
        try salvar()
        return pessoa
    }

    // Cria um lugar já com um cardápio vazio associado.
    @discardableResult
    func criarLugar(nome: String, nomeCardapio: String = "Cardápio") throws -> Restaurante {
        let cardapio = Cardapio(nome: try nomeValidado(nomeCardapio))
        let restaurante = Restaurante(nome: try nomeValidado(nome), cardapio: cardapio)
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

    // Cria uma comanda para um grupo, opcionalmente num restaurante.
    @discardableResult
    func criarComanda(
        nome: String,
        grupo: Grupo,
        restaurante: Restaurante? = nil,
        ativa: Bool = true
    ) throws -> Comanda {
        if ativa {
            try validarComandaAtivaUnica()
        }

        let comanda = Comanda(nome: try nomeValidado(nome), ativa: ativa, restaurante: restaurante, grupo: grupo)
        context.insert(comanda)
        try salvar()
        return comanda
    }

    // Cria uma rodada de pedido dentro de uma comanda ativa.
    @discardableResult
    func criarPedido(comanda: Comanda) throws -> Pedido {
        try validarComandaAtiva(comanda)
        let pedido = Pedido(comanda: comanda)
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

    // Registra quanto um participante pagou no total da comanda.
    func registrarPagamento(_ valorPago: Decimal, para participante: ParticipanteComanda) throws {
        guard valorPago >= 0 else { throw CRUDErro.pagamentoNegativo }
        guard let comanda = participante.comanda else { throw CRUDErro.participanteForaDaComanda }
        try validarComandaAtiva(comanda)

        participante.valorPago = valorPago
        try salvar()
    }

    // Fecha a comanda quando a soma dos pagamentos cobre exatamente o total com taxa de serviço.
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

    // Atualiza os dados de um grupo.
    func atualizarGrupo(_ grupo: Grupo, nome: String) throws {
        grupo.nome = try nomeValidado(nome)
        try salvar()
    }

    // Atualiza os dados editáveis de uma pessoa. O saldo é alterado apenas por comandas fechadas e transferências.
    func atualizarPessoa(_ pessoa: Pessoa, nome: String) throws {
        let nomeValidado = try nomeValidado(nome)
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
    func removerGrupo(_ grupo: Grupo) throws {
        context.delete(grupo)
        try salvar()
    }

    // Remove uma pessoa preservando participações e transferências históricas.
    func removerPessoa(_ pessoa: Pessoa) throws {
        context.delete(pessoa)
        try salvar()
    }

    // Remove um item do cardápio preservando os itens de pedidos históricos.
    func removerItem(_ item: Item) throws {
        context.delete(item)
        try salvar()
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

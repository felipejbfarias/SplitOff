import Foundation
import SwiftData

@Model
final class ParticipanteComanda {
    var id: UUID = UUID()
    var contaAtualPaga: Bool = false

    var comanda: Comanda?
    var pessoa: Pessoa?

    /// Itens que esta pessoa divide nesta comanda (lado inverso da relação
    /// muitos-para-muitos declarada em `ItemPedido.donos`).
    var itensConsumidos: [ItemPedido] = []

    /// Total que esta pessoa deve nesta comanda: para cada item que ela divide,
    /// soma a sua fração (preço do item ÷ nº de donos). Calculado.
    var contaAtual: Decimal {
        itensConsumidos.reduce(0) { $0 + $1.precoPorDono }
    }

    init(
        pessoa: Pessoa? = nil,
        comanda: Comanda? = nil,
        contaAtualPaga: Bool = false
    ) {
        self.pessoa = pessoa
        self.comanda = comanda
        self.contaAtualPaga = contaAtualPaga
    }

    /// Remove esta participação da comanda. Os itens em que esta pessoa era a
    /// ÚNICA dona ficariam órfãos (todo item precisa ter dono), então são
    /// apagados. Itens com outros donos apenas perdem esta pessoa.
    ///
    /// É um fluxo raro — ocorre sobretudo ao excluir a Pessoa do histórico —,
    /// então o `valorTotal` da comanda e os saldos podem ficar desatualizados,
    /// o que é aceito por design. Precisa ser chamado explicitamente: uma
    /// exclusão em cascata crua (apagar a Pessoa direto no contexto) não roda
    /// esta limpeza.
    func remover(de context: ModelContext) {
        for item in itensConsumidos where item.donos.count == 1 {
            context.delete(item)
        }
        context.delete(self)
    }
}

@Model
final class Comanda {
    var id: UUID = UUID()
    var nome: String
    var data: Date = Date.now
    var ativa: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \Restaurante.comandas)
    var restaurante: Restaurante?

    var grupo: Grupo?

    @Relationship(deleteRule: .cascade, inverse: \ParticipanteComanda.comanda)
    var participantes: [ParticipanteComanda] = []

    @Relationship(deleteRule: .cascade, inverse: \Pedido.comanda)
    var pedidos: [Pedido] = []

    /// Valor cheio da comanda: soma do preço de todos os itens de todos os
    /// pedidos (a conta do restaurante). Calculado.
    var valorTotal: Decimal {
        pedidos.reduce(0) { $0 + $1.valorTotal }
    }

    init(
        nome: String,
        data: Date = Date.now,
        ativa: Bool = false,
        restaurante: Restaurante? = nil,
        grupo: Grupo? = nil
    ) {
        self.nome = nome
        self.data = data
        self.ativa = ativa
        self.restaurante = restaurante
        self.grupo = grupo
    }

    /// Adiciona uma pessoa como participante desta comanda, garantindo o
    /// vínculo: a pessoa precisa pertencer ao mesmo grupo da comanda.
    /// Retorna o participante criado, ou `nil` se a pessoa não for do grupo.
    @discardableResult
    func adicionarParticipante(_ pessoa: Pessoa) -> ParticipanteComanda? {
        guard pessoa.grupo == grupo else { return nil }
        let participante = ParticipanteComanda(pessoa: pessoa, comanda: self)
        participantes.append(participante)
        return participante
    }
}

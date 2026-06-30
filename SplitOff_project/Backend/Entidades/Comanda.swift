import Foundation
import SwiftData

@Model
final class ParticipanteComanda {
    var id: UUID = UUID()
    var valorPago: Decimal = 0
    var nomePessoa: String

    var comanda: Comanda?
    var pessoa: Pessoa?

    // Itens que esta pessoa divide nesta comanda (inverso de ItemPedido.donos).
    var itensConsumidos: [ItemPedido] = []

    // Total dos itens que esta pessoa divide, sem taxa de serviço.
    var subtotalContaAtual: Decimal {
        itensConsumidos.reduce(0) { $0 + $1.precoPorDono }
    }

    var taxaServicoAtual: Decimal {
        subtotalContaAtual * Comanda.taxaServicoPercentual
    }

    // Total que esta pessoa deve, com taxa de serviço obrigatória.
    var contaAtual: Decimal {
        subtotalContaAtual + taxaServicoAtual
    }

    init(
        pessoa: Pessoa? = nil,
        comanda: Comanda? = nil,
        valorPago: Decimal = 0,
        nomePessoa: String? = nil
    ) {
        self.pessoa = pessoa
        self.comanda = comanda
        self.valorPago = valorPago
        self.nomePessoa = nomePessoa ?? pessoa?.nome ?? ""
    }
}

@Model
final class Comanda {
    static let taxaServicoPercentual = Decimal(10) / Decimal(100)
    static let limiarFechamento = Decimal(1) / Decimal(100)

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

    // Valor dos itens antes da taxa de serviço.
    var subtotal: Decimal {
        pedidos.reduce(0) { $0 + $1.valorTotal }
    }

    var taxaServico: Decimal {
        subtotal * Self.taxaServicoPercentual
    }

    // Valor cheio da comanda, já com a taxa de serviço obrigatória de 10%.
    var valorTotal: Decimal {
        subtotal + taxaServico
    }

    var valorPago: Decimal {
        participantes.reduce(0) { $0 + $1.valorPago }
    }

    var podeFechar: Bool {
        abs(valorPago - valorTotal) <= Self.limiarFechamento
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

}

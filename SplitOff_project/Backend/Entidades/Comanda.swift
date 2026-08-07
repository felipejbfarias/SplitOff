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

    // Total dos itens que esta pessoa divide, sem extras da comanda.
    var subtotalContaAtual: Decimal {
        itensConsumidos.reduce(0) { $0 + $1.precoPorDono }
    }

    var taxaServicoAtual: Decimal {
        guard comanda?.cobraTaxaServico == true else { return 0 }
        return subtotalContaAtual * Comanda.taxaServicoPercentual
    }

    var couvertArtisticoAtual: Decimal {
        comanda?.valorCouvertPorPessoa ?? 0
    }

    // Total que esta pessoa deve, com os extras configurados na comanda.
    var contaAtual: Decimal {
        subtotalContaAtual + taxaServicoAtual + couvertArtisticoAtual
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
    var cobraTaxaServico: Bool = true
    var valorCouvertPorPessoa: Decimal = 0

    @Relationship(deleteRule: .nullify, inverse: \Restaurante.comandas)
    var restaurante: Restaurante?

    var grupo: Grupo?

    @Relationship(deleteRule: .cascade, inverse: \ParticipanteComanda.comanda)
    var participantes: [ParticipanteComanda] = []

    @Relationship(deleteRule: .cascade, inverse: \Pedido.comanda)
    var pedidos: [Pedido] = []

    // Valor dos itens antes dos extras.
    var subtotal: Decimal {
        pedidos.reduce(0) { $0 + $1.valorTotal }
    }

    var taxaServico: Decimal {
        guard cobraTaxaServico else { return 0 }
        return subtotal * Self.taxaServicoPercentual
    }

    var couvertArtistico: Decimal {
        valorCouvertPorPessoa * Decimal(participantes.count)
    }

    // Valor cheio da comanda, já com os extras configurados.
    var valorTotal: Decimal {
        subtotal + taxaServico + couvertArtistico
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
        cobraTaxaServico: Bool = true,
        valorCouvertPorPessoa: Decimal = 0,
        restaurante: Restaurante? = nil,
        grupo: Grupo? = nil
    ) {
        self.nome = nome
        self.data = data
        self.ativa = ativa
        self.cobraTaxaServico = cobraTaxaServico
        self.valorCouvertPorPessoa = valorCouvertPorPessoa
        self.restaurante = restaurante
        self.grupo = grupo
    }

}

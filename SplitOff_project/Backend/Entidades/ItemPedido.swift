import Foundation
import SwiftData

@Model
final class ItemPedido {
    var id: UUID = UUID()
    var nome: String
    var preco: Decimal = 0

    var pedido: Pedido?

    @Relationship(deleteRule: .nullify, inverse: \Item.itensPedido)
    var itemCardapio: Item?

    // Participantes que dividem este item.
    @Relationship(inverse: \ParticipanteComanda.itensConsumidos)
    var donos: [ParticipanteComanda] = []

    init(
        nome: String,
        preco: Decimal = 0,
        donos: [ParticipanteComanda],
        itemCardapio: Item? = nil
    ) {
        self.nome = nome
        self.preco = preco
        self.donos = donos
        self.itemCardapio = itemCardapio
    }

    // Quanto cada dono paga: preço dividido igualmente entre os donos.
    var precoPorDono: Decimal {
        guard !donos.isEmpty else { return 0 }
        return preco / Decimal(donos.count)
    }
}

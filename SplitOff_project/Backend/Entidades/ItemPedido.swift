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

    /// Pessoas (participantes da comanda) que dividem este item.
    /// Muitos-para-muitos: um item pode ter vários donos e um participante
    /// pode ser dono de vários itens.
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

    /// Quanto cada dono paga deste item: preço dividido igualmente entre os donos.
    /// Um item sempre tem ao menos um dono (garantido no init); o `max(..., 1)`
    /// é só uma proteção contra divisão por zero. Valor exato, sem arredondar —
    /// a exibição em 2 casas é responsabilidade da camada de UI.
    var precoPorDono: Decimal {
        preco / Decimal(max(donos.count, 1))
    }
}

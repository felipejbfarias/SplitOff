import Foundation
import SwiftData

@Model
final class Pedido {
    var id: UUID = UUID()

    var comanda: Comanda?

    @Relationship(deleteRule: .cascade, inverse: \ItemPedido.pedido)
    var itens: [ItemPedido] = []

    init(comanda: Comanda? = nil) {
        self.comanda = comanda
    }

    // Valor cheio do pedido: soma do preço de todos os itens.
    var valorTotal: Decimal {
        itens.reduce(0) { $0 + $1.preco }
    }
}

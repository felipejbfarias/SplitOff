import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID = UUID()
    var nome: String
    var preco: Decimal = 0

    var cardapio: Cardapio?
    var itensPedido: [ItemPedido] = []

    init(nome: String, preco: Decimal = 0, cardapio: Cardapio? = nil) {
        self.nome = nome
        self.preco = preco
        self.cardapio = cardapio
    }
}

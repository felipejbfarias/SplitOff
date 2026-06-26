import Foundation
import SwiftData

@Model
final class Restaurante {
    var id: UUID = UUID()
    var nome: String

    @Relationship(deleteRule: .cascade, inverse: \Cardapio.restaurante)
    var cardapio: Cardapio?

    var comandas: [Comanda] = []

    init(nome: String, cardapio: Cardapio? = nil) {
        self.nome = nome
        self.cardapio = cardapio
    }
}

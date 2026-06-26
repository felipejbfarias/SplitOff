import Foundation
import SwiftData

@Model
final class Cardapio {
    var id: UUID = UUID()
    var nome: String

    var restaurante: Restaurante?

    @Relationship(deleteRule: .cascade, inverse: \Item.cardapio)
    var itens: [Item] = []

    init(nome: String) {
        self.nome = nome
    }
}

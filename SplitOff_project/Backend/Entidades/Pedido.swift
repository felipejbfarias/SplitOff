import Foundation
import SwiftData

@Model
final class Pedido {
    var id: UUID = UUID()

    // Ordem do pedido na comanda.
    var numero: Int = 0

    var comanda: Comanda?

    @Relationship(deleteRule: .cascade, inverse: \ItemPedido.pedido)
    var itens: [ItemPedido] = []

    init(numero: Int = 0, comanda: Comanda? = nil) {
        self.numero = numero
        self.comanda = comanda
    }

    // Valor cheio do pedido: soma do preço de todos os itens.
    var valorTotal: Decimal {
        itens.reduce(0) { $0 + $1.preco }
    }

    // Nomes distintos das pessoas que participam do pedido, ex.: "Ana, Bruno".
    var responsaveis: String {
        var nomes: [String] = []
        for item in itens {
            for dono in item.donos where !nomes.contains(dono.nomePessoa) {
                nomes.append(dono.nomePessoa)
            }
        }
        return nomes.joined(separator: ", ")
    }
}

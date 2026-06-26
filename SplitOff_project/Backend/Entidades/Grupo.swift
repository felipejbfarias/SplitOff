import Foundation
import SwiftData

@Model
final class Grupo {
    var id: UUID = UUID()
    var nome: String

    @Attribute(.externalStorage)
    var foto: Data?

    @Relationship(deleteRule: .cascade, inverse: \Pessoa.grupo)
    var pessoas: [Pessoa] = []

    @Relationship(deleteRule: .cascade, inverse: \Comanda.grupo)
    var comandas: [Comanda] = []

    init(nome: String, foto: Data? = nil) {
        self.nome = nome
        self.foto = foto
    }
}

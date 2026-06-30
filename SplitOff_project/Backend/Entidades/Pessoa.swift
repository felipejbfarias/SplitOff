import Foundation
import SwiftData

@Model
final class Pessoa {
    var id: UUID = UUID()
    var nome: String
    var saldo: Decimal = 0

    var grupo: Grupo?

    @Relationship(deleteRule: .nullify, inverse: \ParticipanteComanda.pessoa)
    var participacoesComanda: [ParticipanteComanda] = []

    init(
        nome: String,
        saldo: Decimal = 0,
        grupo: Grupo? = nil
    ) {
        self.nome = nome
        self.saldo = saldo
        self.grupo = grupo
    }

}

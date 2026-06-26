import Foundation
import SwiftData

@Model
final class Pessoa {
    var id: UUID = UUID()
    var nome: String
    var saldo: Decimal = 0

    var grupo: Grupo?

    @Relationship(deleteRule: .cascade, inverse: \ParticipanteComanda.pessoa)
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

    /// Exclui a pessoa de forma segura. Antes de apagá-la, remove cada uma de
    /// suas participações via `ParticipanteComanda.remover(de:)`, garantindo a
    /// limpeza dos itens órfãos (aqueles em que ela era a única dona). Use este
    /// método em vez de `context.delete(pessoa)` direto, que dispararia o
    /// cascade sem rodar essa limpeza.
    func excluir(de context: ModelContext) {
        for participacao in participacoesComanda {
            participacao.remover(de: context)
        }
        context.delete(self)
    }
}

import Foundation
import SwiftData

// Monta o banco local usado pelo app.
enum Persistencia {
    // Container persistido em disco.
    static let container: ModelContainer = {
        let schema = Schema(splitOffModels)
        let configuracao = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuracao])

            // Desde a primeira inicialização existe o grupo Você
            try? CRUD(context: container.mainContext).garantirGrupoVoce()

            return container
        } catch {
            fatalError("Falha ao criar o ModelContainer: \(error)")
        }
    }()
}

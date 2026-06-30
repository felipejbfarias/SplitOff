import Foundation
import SwiftData

// Monta o banco local usado pelo app.
enum Persistencia {
    // Container persistido em disco.
    static let container: ModelContainer = {
        let schema = Schema(splitOffModels)
        let configuracao = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuracao])
        } catch {
            fatalError("Falha ao criar o ModelContainer: \(error)")
        }
    }()
}

import Foundation
import SwiftData

/// Ponto central que monta o banco local (SwiftData, sem nuvem) usado pelo app.
enum Persistencia {
    /// Container compartilhado, persistido em disco no dispositivo.
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

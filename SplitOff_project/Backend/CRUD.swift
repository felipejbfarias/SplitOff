import Foundation
import SwiftData

@MainActor
final class CRUD {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }
}

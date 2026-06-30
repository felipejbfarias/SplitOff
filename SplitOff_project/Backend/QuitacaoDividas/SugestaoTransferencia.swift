import Foundation

struct SugestaoTransferencia: Identifiable {
    let id: UUID = UUID()
    let devedor: Pessoa
    let credor: Pessoa
    let valor: Decimal
}

import Foundation

enum PlanejadorQuitacaoDividas {
    static func calcularSugestoes(para grupo: Grupo) -> [SugestaoTransferencia] {
        var pagadores = Heap<Pessoa>(comparePor: { $0.saldo > $1.saldo })
        var recebedores = Heap<Pessoa>(comparePor: { $0.saldo > $1.saldo })
        
        // Vambora Davizaoo!!
        // Entrada: pessoas do grupo com saldo negativo devem pagar, pessoas com saldo positivo devem receber.
        // Saida: menor conjunto possivel de sugestoes de transferencias de devedores para credores.
        return []
    }
}

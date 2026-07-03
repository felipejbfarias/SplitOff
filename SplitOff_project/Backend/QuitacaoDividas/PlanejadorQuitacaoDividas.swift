import Foundation

enum PlanejadorQuitacaoDividas {
    static func calcularSugestoes(para grupo: Grupo) -> [SugestaoTransferencia]
    {
        var sugestoesTransferencia: [SugestaoTransferencia] = []
        var pagadores = Heap<Pessoa>(comparePor: { $0.saldo > $1.saldo })
        var recebedores = Heap<Pessoa>(comparePor: { $0.saldo > $1.saldo })

        for pessoa in grupo.pessoas {
            if pessoa.saldo < 0 {
                pagadores.insert(pessoa)
            } else if pessoa.saldo > 0 {
                recebedores.insert(pessoa)
            }
        }

        while !pagadores.isEmpty {
            guard let pagador = pagadores.remove() else { break }
            guard let recebedor = recebedores.remove()
            else { break }
            
            let valor = min(-pagador.saldo, recebedor.saldo)
            
            let sugestaoTransferencia = SugestaoTransferencia(
                devedor: pagador,
                credor: recebedor,
                valor: valor,
            )
            
            sugestoesTransferencia.append(sugestaoTransferencia)
            
            pagador.saldo += valor
            recebedor.saldo -= valor
            
            if (pagador.saldo < 0) {
                pagadores.insert(pagador)
            } else if (recebedor.saldo > 0) {
                recebedores.insert(recebedor)
            }
        }
        // Vambora Davizaoo!!
        // Entrada: pessoas do grupo com saldo negativo devem pagar, pessoas com saldo positivo devem receber.
        // Saida: menor conjunto possivel de sugestoes de transferencias de devedores para credores.
        return sugestoesTransferencia
    }
}

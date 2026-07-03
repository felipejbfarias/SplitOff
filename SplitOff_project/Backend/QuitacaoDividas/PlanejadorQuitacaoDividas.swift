import Foundation

enum PlanejadorQuitacaoDividas {
    // VAMBORA DAVIZAOOOO

    // Par pessoa + saldo restante usado só durante o cálculo.
    // O algoritmo trabalha nessas cópias: o saldo real das Pessoas nunca é alterado aqui,
    private struct Pendencia {
        let pessoa: Pessoa
        var saldo: Decimal
    }

    static func calcularSugestoes(para grupo: Grupo) -> [SugestaoTransferencia] {
        var sugestoes: [SugestaoTransferencia] = []

        // Maior dívida no topo de um heap, maior crédito no topo do outro.
        let pagadores = Heap<Pendencia>(comparePor: { $0.saldo < $1.saldo })
        let recebedores = Heap<Pendencia>(comparePor: { $0.saldo > $1.saldo })

        for pessoa in grupo.pessoas {
            if pessoa.saldo < 0 {
                pagadores.insert(Pendencia(pessoa: pessoa, saldo: pessoa.saldo))
            } else if pessoa.saldo > 0 {
                recebedores.insert(Pendencia(pessoa: pessoa, saldo: pessoa.saldo))
            }
        }

        // Cada rodada casa o maior devedor com o maior credor e zera pelo menos um dos dois.
        while let pagador = pagadores.remove(), let recebedor = recebedores.remove() {
            let valor = min(-pagador.saldo, recebedor.saldo)

            sugestoes.append(SugestaoTransferencia(
                devedor: pagador.pessoa,
                credor: recebedor.pessoa,
                valor: valor
            ))

            var restantePagador = pagador
            restantePagador.saldo += valor
            if restantePagador.saldo < 0 {
                pagadores.insert(restantePagador)
            }

            var restanteRecebedor = recebedor
            restanteRecebedor.saldo -= valor
            if restanteRecebedor.saldo > 0 {
                recebedores.insert(restanteRecebedor)
            }
        }

        return sugestoes
    }
}

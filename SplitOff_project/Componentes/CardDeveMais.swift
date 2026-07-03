//
//  CardDeveMais.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Mostra as 3 maiores dívidas do grupo
struct CardDeveMais: View {
    let grupo: Grupo

    // Alturas da maçã
    private let alturaMaxima: CGFloat = 190
    private let alturaMinima: CGFloat = 110
    private let alturaCard: CGFloat = 240

    // Uma pessoa devendo, já com o valor positivo da dívida.
    private struct Devedor: Identifiable {
        let id: UUID
        let nome: String
        let valor: Decimal
    }

    // Os 3 maiores devedores
    private var maioresDevedores: [Devedor] {
        grupo.pessoas
            .filter { $0.saldo < 0 }
            .sorted { $0.saldo < $1.saldo }
            .prefix(3)
            .map { Devedor(id: $0.id, nome: $0.nome, valor: abs($0.saldo)) }
    }

    // Ordem de exibição em pódio: maior no meio, 2ª à esquerda, 3ª à direita.
    private var ordemPodio: [Devedor] {
        let d = maioresDevedores
        switch d.count {
            case 0: return []
            case 1: return [d[0]]
            case 2: return [d[1], d[0]]
            default: return [d[1], d[0], d[2]]
        }
    }

    var body: some View {
        Group {
            if ordemPodio.isEmpty {
                Text("Ninguém está devendo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(ordemPodio) { devedor in
                        maca(devedor)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: alturaCard)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    // Maçã com nome e valor cravados no corpo.
    private func maca(_ devedor: Devedor) -> some View {
        let altura = alturaPara(devedor.valor)
        return Image("maca_inteira")
            .resizable()
            .scaledToFit()
            .frame(height: altura)
            .overlay {
                VStack(spacing: 2) {
                    Text(devedor.nome)
                    Text(moeda(devedor.valor))
                }
                .font(.system(size: altura * 0.11, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, altura * 0.1)
                // Desce o texto do centro do frame para o corpo da maçã (abaixo do palito).
                .offset(y: altura * 0.15)
            }
    }

    // Altura proporcional ao valor: a maior dívida ocupa o teto
    private func alturaPara(_ valor: Decimal) -> CGFloat {
        guard let maior = maioresDevedores.first?.valor, maior > 0 else { return alturaMinima }
        let razao = decimalParaDouble(valor) / decimalParaDouble(maior)
        return max(alturaMinima, alturaMaxima * razao)
    }

    private func moeda(_ valor: Decimal) -> String {
        valor.formatted(.currency(code: "BRL"))
    }

    private func decimalParaDouble(_ valor: Decimal) -> Double {
        NSDecimalNumber(decimal: valor).doubleValue
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!

    
    let _ = {
        let crud = CRUD(context: context)
        for pessoa in grupo.pessoas { pessoa.saldo = 0 }
        let alvos: [String: Decimal] = ["Matheus": -140, "Davi": -200, "Felipe": -10, "Ana": 240]
        for (nome, saldo) in alvos {
            let pessoa = grupo.pessoas.first { $0.nome == nome }
                ?? (try! crud.criarPessoa(nome: nome, grupo: grupo))
            pessoa.saldo = saldo
        }
    }()

    ScrollView {
        CardDeveMais(grupo: grupo)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(DadosDeExemplo.container)
}

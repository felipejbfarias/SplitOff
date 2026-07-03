//
//  CardProgresso.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Acompanha o pagamento da comanda ativa: barra de progresso do quanto já foi pago
struct CardProgresso: View {
    let comanda: Comanda

    // Quanto ainda falta pagar
    private var falta: Decimal {
        max(0, comanda.valorTotal - comanda.valorPago)
    }

    private var pago: Bool {
        comanda.podeFechar
    }

    // fracao para preenchimento da barra.
    private var fracao: Double {
        guard comanda.valorTotal > 0 else { return 0 }
        let razao = decimalParaDouble(comanda.valorPago) / decimalParaDouble(comanda.valorTotal)
        
        return min(max(razao, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pagamento")
                    .font(.system(size: 17, weight: .semibold))

                Spacer()

                if pago {
                    Text("Pago")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                
                else {
                    Text("Falta \(moeda(falta))")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.accent)
                }
            }

            barra

            Text("\(moeda(comanda.valorPago)) pago de \(moeda(comanda.valorTotal))")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    // Barra de progresso do valor pago
    private var barra: some View {
        GeometryReader { geometria in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))

                Capsule()
                    .fill(.accent)
                    .frame(width: geometria.size.width * fracao)
            }
        }
        .frame(height: 12)
        .animation(.easeInOut(duration: 0.3), value: fracao)
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
    let voce = grupo.pessoas.first { $0.nome == "Você" }
        ?? (try! CRUD(context: context).criarPessoa(nome: "Você", grupo: grupo))

    func comanda(pago: Decimal) -> Comanda {
        let lugar = Restaurante(nome: "Mamute", cardapio: Cardapio(nome: "Cardápio"))
        let comanda = Comanda(nome: "Rolê", ativa: true, restaurante: lugar, grupo: grupo)
        context.insert(comanda)
        let participante = ParticipanteComanda(pessoa: voce, comanda: comanda, valorPago: pago)
        let pedido = Pedido(numero: 1, comanda: comanda)
        let item = ItemPedido(nome: "Rodízio", preco: 140, donos: [participante])
        item.pedido = pedido
        return comanda
    }

    return ScrollView {
        VStack(spacing: 20) {
            CardProgresso(comanda: comanda(pago: 132))
            CardProgresso(comanda: comanda(pago: 154))
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(DadosDeExemplo.container)
}

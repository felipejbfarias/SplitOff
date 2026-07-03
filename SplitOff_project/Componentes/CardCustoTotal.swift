//
//  CardCustoTotal.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Resumo do custo da comanda ativa
struct CardCustoTotal: View {
    let comanda: Comanda

    var body: some View {
        VStack(spacing: 16) {
            Text("Total")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(.secondary)

            Text(moeda(comanda.valorTotal))
                .font(.system(size: 34, weight: .bold))
                .contentTransition(.numericText())

            HStack {
                Text("Conta: \(moeda(comanda.subtotal))")
                Spacer()
                Text("Taxa de serviço: \(moeda(comanda.taxaServico))")
            }
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    private func moeda(_ valor: Decimal) -> String {
        valor.formatted(.currency(code: "BRL"))
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let comandas = try! context.fetch(FetchDescriptor<Comanda>())
    let comanda = comandas.first { $0.ativa } ?? comandas.first!

    ScrollView {
        CardCustoTotal(comanda: comanda)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(DadosDeExemplo.container)
}

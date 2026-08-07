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

            VStack(spacing: 8) {
                linha("Conta", valor: comanda.subtotal)

                if comanda.cobraTaxaServico {
                    linha("Taxa de serviço", valor: comanda.taxaServico)
                }

                if comanda.valorCouvertPorPessoa > 0 {
                    linha("Couvert artístico", valor: comanda.couvertArtistico)
                }
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

    private func linha(_ titulo: String, valor: Decimal) -> some View {
        HStack {
            Text(titulo)
            Spacer()
            Text(moeda(valor))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
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

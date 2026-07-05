//
//  LiveActivitiesTelaDesbloqueada.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI

// Conteúdo compacto da Dynamic Island
struct LiveActivitiesTelaDesbloqueada: View {
    let gastoVoce: Decimal
    var mostrarIcone: Bool = true

    var body: some View {
        HStack(spacing: 6) {
            if mostrarIcone {
                Image(systemName: "person.fill")
                    .font(.footnote)
            }

            // Centavos só quando existem
            Text(gastoVoce.formatted(.currency(code: "BRL").precision(.fractionLength(0...2))))
                .font(.caption2.weight(.bold))
                .contentTransition(.numericText())
        }
        .foregroundStyle(.accent)
    }
}

#Preview {
    LiveActivitiesTelaDesbloqueada(gastoVoce: Decimal(string: "77.75")!)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.black, in: .capsule)
        .padding()
}

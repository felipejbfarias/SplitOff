//
//  LiveActivitiesTelaBloqueio.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI

// Card da Live Activity na tela bloqueada: evento e lugar em cima,
struct LiveActivitiesTelaBloqueio: View {
    let nomeEvento: String
    let nomeLugar: String
    let gastoVoce: Decimal
    let totalMesa: Decimal

    @Environment(\.colorScheme) private var esquema

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(nomeEvento)
                Spacer()
                Text(nomeLugar)
            }
            .font(.subheadline.weight(.semibold))

            ZStack {
                // A maçã cravada no centro exato do card, sobre metades iguais.
                Image("maca_cortada")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 76)

                HStack(alignment: .center, spacing: 0) {
                    coluna(rotulo: "Você", simbolo: "person.fill", valor: gastoVoce)
                        .frame(maxWidth: .infinity)

                    // Vão reservado para a maçã.
                    Color.clear.frame(width: 92, height: 1)

                    coluna(rotulo: "Mesa", simbolo: "person.3.fill", valor: totalMesa)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        // Preto sobre o vidro claro do light mode, rosa no escuro.
        .foregroundStyle(esquema == .dark ? Color.pink : .black)
        .padding(16)
    }

    // Rótulo com ícone em cima e o valor em destaque embaixo.
    private func coluna(rotulo: String, simbolo: String, valor: Decimal) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: simbolo)
                    .font(.footnote)
                Text(rotulo)
                    .font(.subheadline.weight(.semibold))
            }

            Text(valor.formatted(.currency(code: "BRL")))
                .font(.title3.bold())
                .contentTransition(.numericText())
        }
    }
}

#Preview("Claro") {
    LiveActivitiesTelaBloqueio(
        nomeEvento: "São JoADA",
        nomeLugar: "Bar do Pinto",
        gastoVoce: Decimal(string: "77.75")!,
        totalMesa: Decimal(string: "532.69")!
    )
    .background(.regularMaterial, in: .rect(cornerRadius: 24))
    .padding()
}

#Preview("Escuro") {
    LiveActivitiesTelaBloqueio(
        nomeEvento: "São JoADA",
        nomeLugar: "Bar do Pinto",
        gastoVoce: Decimal(string: "77.75")!,
        totalMesa: Decimal(string: "532.69")!
    )
    .background(.regularMaterial, in: .rect(cornerRadius: 24))
    .padding()
    .preferredColorScheme(.dark)
}

//
//  TopBar.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI

struct TopBar: View {
    @Environment(\.dismiss) private var dismiss

    var mostrarVoltar: Bool = true
    var aoVoltar: (() -> Void)? = nil

    var simboloDireita: String? = nil
    var acaoDireita: (() -> Void)? = nil

    var body: some View {
        HStack {
            if mostrarVoltar {
                botao("chevron.left") { (aoVoltar ?? { dismiss() })() }
            }

            Spacer()

            if let simboloDireita, let acaoDireita {
                botao(simboloDireita, acao: acaoDireita)
            }
        }
        .padding(.horizontal)
    }

    // Botão circular da top bar
    private func botao(_ simbolo: String, acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            Image(systemName: simbolo)
                .font(.system(size: 24, weight: .medium))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()

        VStack(spacing: 32) {
            // Voltar + editar
            TopBar(simboloDireita: "pencil") { print("Abrir sheet editar") }

            // Voltar + adicionar pessoa
            TopBar(simboloDireita: "person.fill.badge.plus") { print("Abrir sheet pessoas") }

            // Só voltar
            TopBar()

            // Só +
            TopBar(mostrarVoltar: false, simboloDireita: "plus") { print("Abrir sheet / navegar") }
        }
    }
}

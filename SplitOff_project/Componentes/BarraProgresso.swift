//
//  BarraProgresso.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI

// As 3 etapas do fluxo de criação de um pedido.
enum EtapaPedido: Int, CaseIterable {
    case escolherPessoas = 1   // Tela Escolher Pessoas
    case cardapio        = 2   // Tela Cardápio
    case itensDividir    = 3   // Tela Itens para dividir

    var progresso: Double {
        Double(rawValue) / Double(EtapaPedido.allCases.count)
    }
}

struct BarraProgresso: View {
    // Etapa atual do fluxo. É isso que define o preenchimento da barra.
    let etapa: EtapaPedido

    private let altura: CGFloat = 12

    var body: some View {
        GeometryReader { geometria in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))

                Capsule()
                    .fill(.accent)
                    .frame(width: geometria.size.width * etapa.progresso)
            }
        }
        .frame(height: altura)
        .animation(.easeInOut(duration: 0.3), value: etapa)
    }
}

#Preview {
    VStack(spacing: 32) {
        BarraProgresso(etapa: .escolherPessoas)
        BarraProgresso(etapa: .cardapio)
        BarraProgresso(etapa: .itensDividir)
    }
    .padding()
}

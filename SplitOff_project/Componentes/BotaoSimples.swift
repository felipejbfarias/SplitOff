//
//  BotaoSimples.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI

struct BotaoSimples1: View {
    let titulo: String
    let acao: () -> Void
    
    var body: some View {
        Button(action: acao) {
            Text(titulo)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonStyle(.glassProminent)
        .tint(.pink)
        .padding(12)
    }
}

#Preview {
    BotaoSimples1(
        titulo: "Criar"
    ) {
    }
}

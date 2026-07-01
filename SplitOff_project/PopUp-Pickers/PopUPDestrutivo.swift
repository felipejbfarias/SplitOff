//
//  PopUPDestrutivo.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Popup destrutivo reutilizável (apagar grupo, deletar item, remover membro, encerrar comanda).

struct PopUPDestrutivo: View {
    let titulo: String // Título em destaque
    let mensagem: String // Texto explicando as consequências da ação
    let textoBotao: String // Rótulo do botão
    let aoConfirmar: () -> Void // Ação destrutiva confirmada
    var aoCancelar: (() -> Void)? = nil // Cancela e fecha o popup

    var body: some View {
        ZStack {
            // Fundo escurecido; tocar fora cancela a ação.
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { aoCancelar?() }

            popup
        }
    }

    private var popup: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(titulo)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(mensagem)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Botão único; tocar fora do cartão cancela.
            Button(role: .destructive) {
                aoConfirmar()
            } label: {
                Text(textoBotao)
                    .font(.system(size: 17, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(Color.red)
            }
            .buttonStyle(.bordered)
            .tint(Color(red: 120 / 255, green: 120 / 255, blue: 128 / 255))
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .padding(.horizontal, 32)
    }
}

extension PopUPDestrutivo {
    // Apagar um grupo e tudo dentro dele.
    static func apagarGrupo(
        _ grupo: Grupo,
        aoConfirmar: @escaping () -> Void,
        aoCancelar: (() -> Void)? = nil
    ) -> PopUPDestrutivo {
        PopUPDestrutivo(
            titulo: "Apagar \(grupo.nome)",
            mensagem: "Todo o histórico, comandas e saldos serão apagados.",
            textoBotao: "Apagar",
            aoConfirmar: aoConfirmar,
            aoCancelar: aoCancelar
        )
    }

    // Apagar uma comanda do histórico.
    static func apagarComanda(
        _ comanda: Comanda,
        aoConfirmar: @escaping () -> Void,
        aoCancelar: (() -> Void)? = nil
    ) -> PopUPDestrutivo {
        PopUPDestrutivo(
            titulo: "Apagar \(comanda.nome)",
            mensagem: "Essa comanda e seus pedidos serão apagados do histórico. Os saldos já fechados das pessoas não mudam.",
            textoBotao: "Apagar",
            aoConfirmar: aoConfirmar,
            aoCancelar: aoCancelar
        )
    }
}

#Preview {
    // Usa um grupo dos dados de exemplo e liga a confirmação ao CRUD.removerGrupo.
    let context = DadosDeExemplo.container.mainContext
    let crud = CRUD(context: context)
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!

    ZStack {
        PopUPDestrutivo(
            titulo: "Apagar \(grupo.nome)",
            mensagem: "Todo o histórico, comandas e saldos serão apagados.",
            textoBotao: "Apagar"
        ) {
            try? crud.removerGrupo(grupo)
        }
    }
}

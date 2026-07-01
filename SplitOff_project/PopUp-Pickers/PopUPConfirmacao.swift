//
//  PopUPConfirmacao.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Popup de confirmação reutilizável, usado para confirmar um pagamento/transferência.

struct PopUPConfirmacao: View {
    let titulo: String  // Título em destaque.
    let mensagem: String // Texto descrevendo o que será registrado.
    let textoBotao: String // Rótulo do botão de ação principal.
    let aoConfirmar: () -> Void // Ação confirmada.
    var aoCancelar: (() -> Void)? = nil // Cancela e fecha o popup.

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
            Button {
                aoConfirmar()
            } label: {
                Text(textoBotao)
                    .font(.system(size: 17, weight: .medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .padding(.horizontal, 32)
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let crud = CRUD(context: context)
    let pessoas = try! context.fetch(FetchDescriptor<Pessoa>())
    let pagador = pessoas[0]
    let recebedor = pessoas[1]
    let valor: Decimal = 27
    let valorTexto = valor.formatted(.currency(code: "BRL").locale(Locale(identifier: "pt_BR")))

    ZStack {
        PopUPConfirmacao(
            titulo: "Confirmar Pagamento",
            mensagem: "Registrar que \(pagador.nome) pagou \(valorTexto) a \(recebedor.nome)?",
            textoBotao: "Confirmar"
        ) {
            _ = try? crud.registrarTransferencia(valor: valor, de: pagador, para: recebedor)
        }
    }
}

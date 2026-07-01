//
//  ListaRowsSeletorStepper.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Uma linha da lista: item do cardápio, donos que dividem e quantidade escolhida.
struct LinhaSeletorStepper: Identifiable {
    let id: UUID
    let item: Item
    var donos: [ParticipanteComanda]
    var quantidade: Int
    let quantidadeMaxima: Int

    var nome: String { item.nome }
    var preco: Decimal { item.preco }

    // já tem donos confirmados no sheet de pessoas
    var selecionado: Bool { !donos.isEmpty }

    // tem dono e quantidade dentro do limite
    var prontoParaCRUD: Bool {
        !donos.isEmpty && quantidade > 0 && quantidade <= quantidadeMaxima
    }
}

// Lista de itens do pedido. O seletor abre o sheet de pessoas e o stepper ajusta a quantidade até o máximo do pedido.

struct ListaRowsSeletorStepper: View {
    @Binding var linhas: [LinhaSeletorStepper]
    
    var aoSelecionar: (LinhaSeletorStepper) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach($linhas) { $linha in
                LinhaView(linha: $linha, aoSelecionar: aoSelecionar)
                if linha.id != linhas.last?.id {
                    Divider().padding(.leading, 56)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}

private struct LinhaView: View {
    @Binding var linha: LinhaSeletorStepper
    var aoSelecionar: (LinhaSeletorStepper) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Seletor
            Button {
                aoSelecionar(linha)
            } label: {
                Image(systemName: linha.selecionado ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(linha.selecionado ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(linha.nome)
                    .font(.headline)
                Text(subtitulo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Quantidade escolhida, só quando selecionado.
            if linha.selecionado {
                Text("\(linha.quantidade)")
                    .font(.headline)
                    .frame(minWidth: 44, minHeight: 34)
                    .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 10))
            }

            // Stepper até o máximo do item no pedido
            StepperQuantidade(
                valor: $linha.quantidade,
                maximo: linha.quantidadeMaxima,
                habilitado: linha.selecionado
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // Selecionado mostra a quantidade máxima, senão, o preço.
    private var subtitulo: String {
        linha.selecionado
            ? "\(linha.quantidade) de \(linha.quantidadeMaxima)"
            : linha.preco.formatted(.currency(code: "BRL"))
    }
}

// Stepper com controle de cor
private struct StepperQuantidade: View {
    @Binding var valor: Int
    let maximo: Int
    var habilitado: Bool

    var body: some View {
        HStack(spacing: 0) {
            botao(simbolo: "minus", ativo: habilitado && valor > 0) { valor -= 1 }
            Divider().frame(height: 20)
            botao(simbolo: "plus", ativo: habilitado && valor < maximo) { valor += 1 }
        }
        .background(Color(.tertiarySystemFill), in: .capsule)
    }

    private func botao(simbolo: String, ativo: Bool, acao: @escaping () -> Void) -> some View {
        Button(action: acao) {
            Image(systemName: simbolo)
                .font(.body.weight(.medium))
                .foregroundStyle(ativo ? Color.primary : Color(.tertiaryLabel))
                .frame(width: 44, height: 34)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!ativo)
    }
}

#Preview {
    @Previewable @State var linhas: [LinhaSeletorStepper] = []
    let context = DadosDeExemplo.container.mainContext
    let itens = (try? context.fetch(FetchDescriptor<Item>())) ?? []
    let participantes = (try? context.fetch(FetchDescriptor<Comanda>()))?.first?.participantes ?? []

    ListaRowsSeletorStepper(linhas: $linhas) { linha in
        // Simula o retorno do sheet: confirma ou limpa os donos do item.
        guard let i = linhas.firstIndex(where: { $0.id == linha.id }) else { return }
        linhas[i].donos = linhas[i].donos.isEmpty ? participantes : []
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .onAppear {
        // Monta as linhas a partir dos itens reais do backend.
        linhas = itens.map {
            LinhaSeletorStepper(
                id: $0.id, item: $0, donos: [],
                quantidade: 0, quantidadeMaxima: 3
            )
        }
    }
}

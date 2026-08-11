//
//  ListaRowsStepper.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Uma linha da lista: item do cardápio e quantidade escolhida para o pedido.
struct LinhaStepper: Identifiable {
    let id: UUID
    let item: Item
    var quantidade: Int

    var nome: String { item.nome }
    var preco: Decimal { item.preco }

    // Entra no pedido quando a quantidade é maior que zero.
    var incluso: Bool { quantidade > 0 }
}

// Lista de itens do cardápio com stepper de quantidade sempre ativo
struct ListaRowsStepper: View {
    @Binding var linhas: [LinhaStepper]

    // Cardápio que recebe o novo item pela row "Adicionar".
    let cardapio: Cardapio

    // Busca digitada na tela do cardápio; vazio mostra tudo.
    var filtro: String = ""

    @State private var mostrandoAdicionar = false
    @State private var fonteScanner: SheetEscanearCardapio.Fonte?

    // Nenhum item bate com a busca (mas o cardápio tem itens).
    private var buscaSemResultado: Bool {
        !linhas.isEmpty && !linhas.contains(where: corresponde)
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach($linhas) { $linha in
                if corresponde(linha) {
                    LinhaStepperView(linha: $linha)
                    Divider().padding(.leading, 16)
                }
            }

            if buscaSemResultado {
                Text("Nenhum item encontrado")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                Divider().padding(.leading, 16)
            }

            // Novo item, digitado ou escaneado de uma foto do cardápio
            Menu {
                Button {
                    mostrandoAdicionar = true
                } label: {
                    Label("Digitar item", systemImage: "keyboard")
                }

                if CameraPicker.disponivel {
                    Button {
                        fonteScanner = .camera
                    } label: {
                        Label("Fotografar cardápio", systemImage: "camera")
                    }
                }

                Button {
                    fonteScanner = .galeria
                } label: {
                    Label("Escanear foto da galeria", systemImage: "photo.on.rectangle")
                }
            } label: {
                HStack {
                    Text("Adicionar")
                        .font(.headline)

                    Spacer()

                    Image(systemName: "text.viewfinder")
                        .font(.body)
                }
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
        .sheet(isPresented: $mostrandoAdicionar) {
            SheetAdicionarItem(cardapio: cardapio)
        }
        .sheet(item: $fonteScanner) { fonte in
            SheetEscanearCardapio(cardapio: cardapio, fonte: fonte)
        }
    }

    // Sem acento e sem caixa, igual às outras buscas do app.
    private func corresponde(_ linha: LinhaStepper) -> Bool {
        let termo = filtro.trimmingCharacters(in: .whitespaces)
        return termo.isEmpty || linha.nome.localizedStandardContains(termo)
    }
}

// Uma linha isolada da lista.
private struct LinhaStepperView: View {
    @Binding var linha: LinhaStepper

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(linha.nome)
                    .font(.headline)
                Text(linha.preco.formatted(.currency(code: "BRL")))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Quantidade
            Text("\(linha.quantidade)")
                .font(.headline)
                .frame(minWidth: 44, minHeight: 34)
                .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 16))

            StepperItem(valor: $linha.quantidade)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// Stepper
private struct StepperItem: View {
    @Binding var valor: Int

    var body: some View {
        HStack(spacing: 0) {
            botao(simbolo: "minus", ativo: valor > 0) { valor -= 1 }
            Divider().frame(height: 20)
            botao(simbolo: "plus", ativo: true) { valor += 1 }
        }
        .background(Color(.tertiarySystemFill), in: .capsule)
    }

    // Um lado do stepper.
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
    @Previewable @State var linhas: [LinhaStepper] = []
    let context = DadosDeExemplo.container.mainContext
    let itens = (try? context.fetch(FetchDescriptor<Item>())) ?? []
    let cardapio = (try? context.fetch(FetchDescriptor<Cardapio>()))?.first

    if let cardapio {
        ListaRowsStepper(linhas: $linhas, cardapio: cardapio)
            .padding()
            .background(Color(.systemGroupedBackground))
            .onAppear {
                linhas = itens.map { LinhaStepper(id: $0.id, item: $0, quantidade: 0) }
            }
            .modelContainer(DadosDeExemplo.container)
    }
}

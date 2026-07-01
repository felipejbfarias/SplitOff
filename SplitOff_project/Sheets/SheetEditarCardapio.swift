//
//  SheetEditarCardapio.swift
//  SplitOff_project
//
//  Created by Felipe José Batista Farias on 6/28/26.
//

import SwiftUI
import SwiftData

// Sheet para editar o cardápio: selecionar itens, editar nome/preço e remover pela lixeira.
struct SheetEditarCardapio: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // Cardápio em edição.
    let cardapio: Cardapio

    // Itens marcados no seletor e os textos digitados por item.
    @State private var selecionados: Set<UUID> = []
    @State private var rascunhos: [UUID: Rascunho] = [:]

    // Item aguardando confirmação de exclusão (mostra o popup destrutivo).
    @State private var itemParaExcluir: Item?

    // Ao editar um campo, expande o sheet para caber o teclado.
    @FocusState private var editando: Bool
    @State private var detente: PresentationDetent = .medium

    // Itens do cardápio em ordem alfabética.
    private var itens: [Item] {
        cardapio.itens.sorted { $0.nome < $1.nome }
    }

    // Itens atualmente selecionados, na mesma ordem da lista.
    private var itensSelecionados: [Item] {
        itens.filter { selecionados.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Qual item deseja editar?") {
                    ForEach(itens) { item in
                        linhaItem(item)
                    }
                }

                // Uma seção de edição para cada item selecionado.
                ForEach(itensSelecionados) { item in
                    Section(item.nome) {
                        TextField("Novo nome", text: bindingNome(item))
                            .focused($editando)
                        TextField("Novo preço", text: bindingPreco(item))
                            .keyboardType(.decimalPad)
                            .focused($editando)
                    }
                }
            }
            .navigationTitle("Editar item do cardápio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", systemImage: "checkmark", action: salvar)
                        .tint(.accentColor)
                        .disabled(selecionados.isEmpty)
                }
            }
        }
        // Confirmação antes de excluir um item do cardápio.
        .overlay {
            if let item = itemParaExcluir {
                PopUPDestrutivo(
                    titulo: "Apagar \(item.nome)",
                    mensagem: "Todo o registro de pedidos com esse item vai ser removido.",
                    textoBotao: "Apagar"
                ) {
                    remover(item)
                    itemParaExcluir = nil
                } aoCancelar: {
                    itemParaExcluir = nil
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $detente)
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemGroupedBackground))
        .onChange(of: editando) { _, ativo in
            if ativo { detente = .large }
        }
    }

    // Linha: seletor + nome/preço + lixeira.
    private func linhaItem(_ item: Item) -> some View {
        let marcado = selecionados.contains(item.id)
        return HStack(spacing: 12) {
            Button {
                alternarSelecao(item)
            } label: {
                Image(systemName: marcado ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(marcado ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.nome)
                Text(item.preco, format: .currency(code: "BRL").locale(Locale(identifier: "pt_BR")))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                itemParaExcluir = item
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }

    // Liga o texto "Novo nome" ao rascunho do item.
    private func bindingNome(_ item: Item) -> Binding<String> {
        Binding(
            get: { rascunhos[item.id]?.nome ?? "" },
            set: { rascunhos[item.id, default: Rascunho()].nome = $0 }
        )
    }

    // Liga o texto "Novo preço" ao rascunho do item.
    private func bindingPreco(_ item: Item) -> Binding<String> {
        Binding(
            get: { rascunhos[item.id]?.preco ?? "" },
            set: { rascunhos[item.id, default: Rascunho()].preco = $0 }
        )
    }

    // Marca/desmarca um item no seletor.
    private func alternarSelecao(_ item: Item) {
        if selecionados.contains(item.id) {
            selecionados.remove(item.id)
        } else {
            selecionados.insert(item.id)
        }
    }

    // Remove o item do cardápio via CRUD.
    private func remover(_ item: Item) {
        selecionados.remove(item.id)
        rascunhos[item.id] = nil
        try? CRUD(context: context).removerItem(item)
    }

    // Aplica os rascunhos dos itens selecionados via CRUD e fecha.
    private func salvar() {
        let crud = CRUD(context: context)
        for item in itensSelecionados {
            let rascunho = rascunhos[item.id] ?? Rascunho()
            let nome = rascunho.nome.trimmingCharacters(in: .whitespaces).isEmpty ? item.nome : rascunho.nome
            let preco = Decimal(string: rascunho.preco.replacingOccurrences(of: ",", with: ".")) ?? item.preco
            try? crud.atualizarItem(item, nome: nome, preco: preco)
        }
        dismiss()
    }

    // Texto digitado para um item enquanto o sheet está aberto.
    private struct Rascunho {
        var nome = ""
        var preco = ""
    }
}

#Preview {
    @Previewable @State var mostrar = false
    let context = DadosDeExemplo.container.mainContext
    let cardapio = try! context.fetch(FetchDescriptor<Cardapio>()).first!

    NavigationStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }
    .task { mostrar = true }
    .sheet(isPresented: $mostrar) {
        SheetEditarCardapio(cardapio: cardapio)
    }
    .modelContainer(DadosDeExemplo.container)
}

//
//  SheetAdicionarItem.swift
//  SplitOff_project
//
//  Created by Felipe José Batista Farias on 6/28/26.
//

import SwiftUI
import SwiftData

// Sheet curto para adicionar um item ao cardápio. Grava via CRUD.criarItem.
struct SheetAdicionarItem: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // Cardápio que vai receber o novo item.
    let cardapio: Cardapio

    @State private var nome = ""
    @State private var precoTexto = ""

    // Foco dos campos: ao editar, expande o sheet para caber o teclado.
    @FocusState private var editando: Bool
    @State private var detente: PresentationDetent = .height(300)

    // Preço digitado convertido para Decimal, aceita vírgula ou ponto.
    private var preco: Decimal? {
        Decimal(string: precoTexto.replacingOccurrences(of: ",", with: "."))
    }

    // Só habilita criar com nome preenchido e preço válido.
    private var podeCriar: Bool {
        !nome.trimmingCharacters(in: .whitespaces).isEmpty && (preco ?? -1) >= 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome do item", text: $nome)
                        .focused($editando)
                    TextField("Preço do item", text: $precoTexto)
                        .keyboardType(.decimalPad)
                        .focused($editando)
                }
            }
            .navigationTitle("Novo Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar", systemImage: "xmark") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                botaoCriar
                    .controlSize(.large)
                    .padding()
            }
        }
        
        // Abre curto e expande para .large enquanto o campo está em foco.
        .presentationDetents([.height(300), .large], selection: $detente)
        .presentationDragIndicator(.visible)
        // Fundo opaco fixo para o detent curto não ficar translúcido/cinza.
        .presentationBackground(Color(.systemGroupedBackground))
        .onChange(of: editando) { _, ativo in
            detente = ativo ? .large : .height(300)
        }
    }

    // Habilitado: glass prominente na cor do app. Desabilitado: glass comum com texto cinza, sem toque.
    @ViewBuilder
    private var botaoCriar: some View {
        if podeCriar {
            Button(action: criarItem) {
                Text("Criar item")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.accentColor)
        } else {
            Button {} label: {
                Text("Criar item")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .allowsHitTesting(false)
        }
    }

    // Cria o item no cardápio e fecha o sheet.
    private func criarItem() {
        let crud = CRUD(context: context)
        guard (try? crud.criarItem(nome: nome, preco: preco ?? 0, cardapio: cardapio)) != nil else { return }
        dismiss()
    }
}

#Preview {
    @Previewable @State var mostrar = false
    let context = DadosDeExemplo.container.mainContext
    let cardapio = try! context.fetch(FetchDescriptor<Cardapio>()).first!

    // Apresenta após aparecer para o sheet abrir animando no detent menor.
    NavigationStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }
    .task { mostrar = true }
    .sheet(isPresented: $mostrar) {
        SheetAdicionarItem(cardapio: cardapio)
    }
    .modelContainer(DadosDeExemplo.container)
}

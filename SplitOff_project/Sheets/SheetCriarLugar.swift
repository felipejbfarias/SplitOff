//
//  SheetCriarLugar.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Sheet curto para adicionar um item ao cardápio. Grava via CRUD.criarItem.
struct SheetCriarLugar: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // Cardápio que vai receber o novo item.
//    let cardapio: Cardapio
//
    @State private var nomeLugar = ""
//    @State private var precoTexto = ""

    @FocusState private var editando: Bool
    @State private var detente: PresentationDetent = .height(300)


    // Só habilita criar com nome preenchido e preço válido.
    private var podeCriar: Bool {
        !nomeLugar.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nome do Lugar", text: $nomeLugar)
                        .focused($editando)
//                    TextField("Preço do item", text: $precoTexto)
//                        .keyboardType(.decimalPad)
//                        .focused($editando)
                }
            }
            .navigationTitle("Criar Lugar")
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
        guard (try? crud.criarLugar(nome: nomeLugar)) != nil else { return }
        dismiss()
    }
}

#Preview {
    @Previewable @State var mostrar = false

    // Apresenta após aparecer para o sheet abrir animando no detent menor.
    NavigationStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }
    .task { mostrar = true }
    .sheet(isPresented: $mostrar) {
        SheetCriarLugar()
    }
    .modelContainer(DadosDeExemplo.container)
}

//
//  SheetSelecionarPessoas.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 01/07/26.
//

import SwiftUI
import SwiftData

// Configura o texto e a seleção inicial conforme o uso do sheet
enum ModoSelecionarPessoas {
    // Escolher quem do grupo entra na comanda: começa tudo marcado
    case grupo(nome: String)
    
    // Escolher com quem dividir um item
    case dividir(autor: String, item: String)

    var subtitulo: String {
        switch self {
            case let .grupo(nome): "Quem do grupo \(nome) vai?"
            case let .dividir(autor, item): "Com quem \(autor) vai dividir \(item)?"
        }
    }

    var iniciaMarcado: Bool {
        switch self {
            case .grupo: true
            case .dividir: false
        }
    }
}

struct SheetSelecionarPessoas<Modelo: Identifiable>: View where Modelo.ID == UUID {
    let modo: ModoSelecionarPessoas
    let pessoas: [Modelo]
    let nome: (Modelo) -> String
    let aoConfirmar: ([Modelo]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var linhas: [LinhaSeletor<Modelo>] = []

    // Altura do sheet: cabeçalho + subtítulo + a lista limitada
    private let alturaLinha: CGFloat = 52
    private let alturaBase: CGFloat = 172
    private let alturaMaxima: CGFloat = 640

    private var altura: CGFloat {
        min(alturaBase + CGFloat(pessoas.count) * alturaLinha, alturaMaxima)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(modo.subtitulo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ListaRowsSeletor(linhas: $linhas, modo: .multipla)
                }
                .padding()
            }
            .scrollBounceBehavior(.basedOnSize)
            .navigationTitle("Selecionar Pessoas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirmar", systemImage: "checkmark", action: confirmar)
                        .tint(.accent)
                }
            }
        }
        .presentationDetents([.height(altura), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemGroupedBackground))
        .onAppear(perform: montarLinhas)
    }

    private func montarLinhas() {
        linhas = pessoas.map {
            LinhaSeletor(id: $0.id, modelo: $0, nome: nome($0), selecionado: modo.iniciaMarcado)
        }
    }

    private func confirmar() {
        aoConfirmar(linhas.filter(\.selecionado).map(\.modelo))
        dismiss()
    }
}

#Preview("Grupo") {
    @Previewable @State var mostrar = false
    let context = DadosDeExemplo.container.mainContext
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!
    let crud = CRUD(context: context)

    let _ = {
        for nome in ["Você", "Matheus", "Felipe", "Davi"] where !grupo.pessoas.contains(where: { $0.nome == nome }) {
            _ = try? crud.criarPessoa(nome: nome, grupo: grupo)
        }
    }()

    let pessoas = grupo.pessoas.sorted { primeira, _ in primeira.nome == "Você" }

    return Color(.systemGroupedBackground).ignoresSafeArea()
        .task { mostrar = true }
        .sheet(isPresented: $mostrar) {
            SheetSelecionarPessoas(
                modo: .grupo(nome: grupo.nome),
                pessoas: pessoas,
                nome: \.nome
            ) { selecionadas in
                print("Vão:", selecionadas.map(\.nome))
            }
        }
        .modelContainer(DadosDeExemplo.container)
}

#Preview("Dividir item") {
    @Previewable @State var mostrar = false
    let context = DadosDeExemplo.container.mainContext
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!
    let crud = CRUD(context: context)

    // Comanda com autor Você e outros participantes para dividir
    let comanda: Comanda = {
        let comanda = Comanda(nome: "Conta", ativa: true, grupo: grupo)
        context.insert(comanda)
        for nome in ["Você", "Matheus", "Felipe", "Davi"] {
            let pessoa = grupo.pessoas.first { $0.nome == nome }
                ?? (try! crud.criarPessoa(nome: nome, grupo: grupo))
            let participante = ParticipanteComanda(pessoa: pessoa, comanda: comanda)
            context.insert(participante)
        }
        return comanda
    }()

    // Todos menos o autor do pedido
    let outros = comanda.participantes.filter { $0.nomePessoa != "Você" }

    return Color(.systemGroupedBackground).ignoresSafeArea()
        .task { mostrar = true }
        .sheet(isPresented: $mostrar) {
            SheetSelecionarPessoas(
                modo: .dividir(autor: "Você", item: "Parmegiana"),
                pessoas: outros,
                nome: \.nomePessoa
            ) { selecionados in
                print("Dividem:", selecionados.map(\.nomePessoa))
            }
        }
        .modelContainer(DadosDeExemplo.container)
}

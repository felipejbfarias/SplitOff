//
//  TabBarManager.swift
//  SplitOff
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// As abas do app
enum AbaPrincipal: Hashable {
    case comanda, grupos, busca
}

// Monta a TabView
struct TabBarManager: View {
    // Se tem comanda ativa, a aba Comanda mostra ela, senão, o histórico de comandas
    @Query(filter: #Predicate<Comanda> { $0.ativa }) private var comandasAtivas: [Comanda]

    @State private var aba: AbaPrincipal = .comanda

    var body: some View {
        TabView(selection: $aba) {
            Tab("Comanda", systemImage: "receipt.fill", value: AbaPrincipal.comanda) {
                NavigationStack {
                    if comandasAtivas.isEmpty {
                        TodasComandasView()
                    } else {
                        ComandaAtualView()
                    }
                }
            }

            Tab("Grupos", systemImage: "person.3.fill", value: AbaPrincipal.grupos) {
                NavigationStack {
                    TodosGruposView()
                }
            }

            Tab("Buscar", systemImage: "magnifyingglass", value: AbaPrincipal.busca, role: .search) {
                NavigationStack {
                    BuscaView()
                }
            }
        }
        // A Live Activity espelha a comanda ativa: nasce com ela e some quando ela fecha
        .onAppear(perform: sincronizarLiveActivity)
        .onChange(of: comandasAtivas.first?.valorTotal) { sincronizarLiveActivity() }
    }

    private func sincronizarLiveActivity() {
        if let comanda = comandasAtivas.first {
            GerenciadorLiveActivity.sincronizar(com: comanda)
        } else {
            GerenciadorLiveActivity.encerrar()
        }
    }
}

#Preview("Com comanda ativa") {
    TabBarManager()
        .modelContainer(DadosDeExemplo.container)
}

#Preview("Sem comanda ativa") {
    let schema = Schema(splitOffModels)
    let configuracao = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuracao])

    let _ = {
        DadosDeExemplo.popular(em: container.mainContext)
        let comandas = try! container.mainContext.fetch(FetchDescriptor<Comanda>())
        for comanda in comandas { comanda.ativa = false }
    }()

    TabBarManager()
        .modelContainer(container)
}

//
//  DetalhamentoGrupoView.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

struct DetalhamentoGrupoView: View {
    @Environment(\.modelContext) private var context
    @Environment(OverlayPresenter.self) private var overlay

    @Bindable var grupo: Grupo

    private enum Aba: String, CaseIterable {
        case historico = "Histórico"
        case membros = "Membros"
    }

    @State private var aba: Aba = .historico
    @State private var mostrarEditarGrupo = false
    @State private var mostrarQuitarDividas = false
    @State private var comandaHistoricoSelecionada: Comanda?
    @State private var mensagemErro: String?

    // O grupo Você é só do dono: sem editar, sem aba de membros e sem quitação.
    private var ehGrupoVoce: Bool {
        grupo.nome == CRUD.nomeVoce
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopBar(
                    mostrarVoltar: true,
                    simboloDireita: ehGrupoVoce ? nil : "person.fill.badge.plus"
                ) {
                    mostrarEditarGrupo = true
                }

                Text(grupo.nome)
                    .font(.system(size: 34, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                if !ehGrupoVoce {
                    Picker("Aba", selection: $aba) {
                        ForEach(Aba.allCases, id: \.self) { aba in
                            Text(aba.rawValue).tag(aba)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }

                ScrollView {
                    switch aba {
                    case .historico:
                        abaHistorico
                    case .membros:
                        abaMembros
                    }
                }

                if aba == .membros, !ehGrupoVoce {
                    BotaoSimples1(titulo: "Quitar") {
                        mostrarQuitarDividas = true
                    }
                    .padding(.bottom, 12)
                }
            }

        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $mostrarEditarGrupo) {
            SheetEditarGrupo(grupo: grupo)
        }
        .sheet(isPresented: $mostrarQuitarDividas) {
            SheetQuitarDividas(grupo: grupo)
        }
        .sheet(item: $comandaHistoricoSelecionada) { comanda in
            SheetHistoricoRole(comanda: comanda)
        }
    }

    private var abaHistorico: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Maiores dívidas")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            CardDeveMais(grupo: grupo)

            Text("Histórico de comandas")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            if let mensagemErro {
                Text(mensagemErro)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
            }

            ForEach(comandasOrdenadas) { comanda in
                RowGrupoHistorico(comanda: comanda) {
                    comandaHistoricoSelecionada = comanda
                } aoRemover: {
                    confirmarRemocao(comanda)
                }
            }
        }
        .padding()
    }

    private var abaMembros: some View {
        ListaRowSaldo(pessoas: grupo.pessoas)
            .padding()
    }

    // A comanda ativa vive na aba Comanda até ser encerrada.
    private var comandasOrdenadas: [Comanda] {
        grupo.comandas
            .filter { !$0.ativa }
            .sorted { $0.data > $1.data }
    }

    // Popup na raiz para escurecer a tela inteira
    private func confirmarRemocao(_ comanda: Comanda) {
        overlay.mostrar(
            PopUPDestrutivo.apagarComanda(comanda) {
                overlay.esconder()
                removerComanda(comanda)
            } aoCancelar: {
                overlay.esconder()
            }
        )
    }

    private func removerComanda(_ comanda: Comanda) {
        let crud = CRUD(context: context)

        do {
            try crud.removerComanda(comanda)
        } catch {
            mensagemErro = error.localizedDescription
        }
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!

    NavigationStack {
        DetalhamentoGrupoView(grupo: grupo)
    }
    .environment(OverlayPresenter())
    .modelContainer(DadosDeExemplo.container)
}

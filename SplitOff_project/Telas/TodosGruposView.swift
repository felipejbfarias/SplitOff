//
//  TodosGrupos.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

struct TodosGruposView: View {
    @Environment(\.modelContext) private var context
    @Environment(OverlayPresenter.self) private var overlay

    @Query(sort: \Grupo.nome)
    private var grupos: [Grupo]

    @State private var mostrarCriarGrupo = false
    @State private var grupoSelecionado: Grupo?
    @State private var mensagemErro: String?


    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopBar(
                    mostrarVoltar: false,
                    simboloDireita: "plus"
                ) {
                    mostrarCriarGrupo = true
                }

                Text("SplitOff")
                    .font(.system(size: 34, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(grupos) { grupo in
                            RowGrupoHistorico(
                                grupo: grupo
                            ) {
                                grupoSelecionado = grupo
                            } aoRemover: {
                                if grupo.nome == CRUD.nomeVoce {
                                    mensagemErro = "O grupo Você não pode ser removido."
                                } else {
                                    confirmarRemocao(grupo)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
            }

        }
        .task {
            garantirGrupoInicial()
        }
        .sheet(isPresented: $mostrarCriarGrupo) {
            SheetCriarGrupo()
        }
        .alert("Erro", isPresented: .constant(mensagemErro != nil)) {
            Button("OK") {
                mensagemErro = nil
            }
        } message: {
            Text(mensagemErro ?? "")
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $grupoSelecionado) { grupo in
            DetalhamentoGrupoView(grupo: grupo)
        }
    }

    private func garantirGrupoInicial() {
        let crud = CRUD(context: context)

        do {
            try crud.garantirGrupoVoce()
        } catch {
            mensagemErro = error.localizedDescription
        }
    }

    // Popup na raiz para escurecer a tela inteira
    private func confirmarRemocao(_ grupo: Grupo) {
        overlay.mostrar(
            PopUPDestrutivo.apagarGrupo(grupo) {
                overlay.esconder()
                removerGrupo(grupo)
            } aoCancelar: {
                overlay.esconder()
            }
        )
    }

    private func removerGrupo(_ grupo: Grupo) {
        let crud = CRUD(context: context)

        do {
            try crud.removerGrupo(grupo)
        } catch {
            mensagemErro = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        TodosGruposView()
    }
    .environment(OverlayPresenter())
    .modelContainer(DadosDeExemplo.container)
}

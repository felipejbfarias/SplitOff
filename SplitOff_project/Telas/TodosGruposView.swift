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

    @Query(sort: \Grupo.nome)
    private var grupos: [Grupo]

    @State private var mostrarCriarGrupo = false
    @State private var grupoParaApagar: Grupo?
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
                    .font(.system(size: 28, weight: .bold))
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
                                    grupoParaApagar = grupo
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
            }

            if let grupoParaApagar {
                PopUPDestrutivo.apagarGrupo(grupoParaApagar) {
                    removerGrupo(grupoParaApagar)
                } aoCancelar: {
                    self.grupoParaApagar = nil
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

    private func removerGrupo(_ grupo: Grupo) {
        let crud = CRUD(context: context)

        do {
            try crud.removerGrupo(grupo)
            grupoParaApagar = nil
        } catch {
            mensagemErro = error.localizedDescription
            grupoParaApagar = nil
        }
    }
}

#Preview {
    NavigationStack {
        TodosGruposView()
    }
    .modelContainer(DadosDeExemplo.container)
}

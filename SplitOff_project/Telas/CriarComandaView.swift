//
//  CriarComandaView.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Criação de comanda
struct CriarComandaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Restaurante.nome) private var restaurantes: [Restaurante]
    @Query(sort: \Grupo.nome) private var grupos: [Grupo]

    @State private var nome = ""
    @State private var lugarSelecionado: String?
    @State private var grupoSelecionado: String?
    @State private var pessoasSelecionadas: [Pessoa] = []

    @State private var mostrarSelecionarPessoas = false
    @State private var mostrarCriarLugar = false
    @State private var mostrarCriarGrupo = false
    @State private var mensagemErro: String?

    private var grupoAtual: Grupo? {
        grupos.first { $0.nome == grupoSelecionado }
    }

    // Pessoas selecionáveis do grupo escolhido
    private var outrosDoGrupo: [Pessoa] {
        (grupoAtual?.pessoas ?? [])
            .filter { $0.nome != CRUD.nomeVoce }
            .sorted { $0.nome < $1.nome }
    }

    private var podeCriar: Bool {
        !nome.trimmingCharacters(in: .whitespaces).isEmpty && grupoAtual != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar()

            Text("Nova Comanda")
                .font(.system(size: 34, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 20) {
                    TextField("Nome do Rolê", text: $nome)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))

                    ListaRowsPicker(
                        titulo: "Informações",
                        linhas: [
                            .picker(
                                titulo: "Lugar",
                                opcoes: restaurantes.map(\.nome),
                                selecao: $lugarSelecionado,
                                temAdicionar: true,
                                acaoAdicionar: { mostrarCriarLugar = true }
                            ),
                            .picker(
                                titulo: "Grupo",
                                opcoes: grupos.map(\.nome),
                                selecao: $grupoSelecionado,
                                temAdicionar: true,
                                acaoAdicionar: { mostrarCriarGrupo = true }
                            ),
                            .sheet(
                                titulo: "Pessoas do grupo",
                                selecionado: grupoAtual != nil,
                                desabilitado: grupoAtual == nil,
                                acao: { mostrarSelecionarPessoas = true }
                            )
                        ]
                    )

                    if let mensagemErro {
                        Text(mensagemErro)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }

            BotaoSimples1(titulo: "Criar Comanda", acao: criarComanda)
                .disabled(!podeCriar)
                .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: grupoSelecionado) {
            pessoasSelecionadas = outrosDoGrupo
        }
        .sheet(isPresented: $mostrarSelecionarPessoas) {
            if let grupoAtual {
                SheetSelecionarPessoas(
                    modo: .grupo(nome: grupoAtual.nome),
                    pessoas: outrosDoGrupo,
                    fixos: [CRUD.nomeVoce],
                    nome: \.nome
                ) { selecionadas in
                    pessoasSelecionadas = selecionadas
                }
            }
        }
        .sheet(isPresented: $mostrarCriarLugar) {
            SheetCriarLugar()
        }
        .sheet(isPresented: $mostrarCriarGrupo) {
            // O grupo recém-criado já entra selecionado no picker.
            SheetCriarGrupo { grupo in
                grupoSelecionado = grupo.nome
            }
        }
    }

    // Cria a comanda já ativa com os participantes escolhidos
    private func criarComanda() {
        guard let grupo = grupoAtual else { return }

        let crud = CRUD(context: modelContext)
        let restaurante = restaurantes.first { $0.nome == lugarSelecionado }

        do {
            // O criarComanda já coloca você como participante.
            let comanda = try crud.criarComanda(nome: nome, grupo: grupo, restaurante: restaurante)
            for pessoa in pessoasSelecionadas where pessoa.nome != CRUD.nomeVoce {
                try crud.adicionarParticipante(pessoa, a: comanda)
            }

            // Desempilha esta tela, com a comanda ativa criada
            dismiss()
        } catch {
            mensagemErro = error.localizedDescription
        }
    }
}

#Preview {
    let schema = Schema(splitOffModels)
    let configuracao = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuracao])
    let context = container.mainContext

    let _ = {
        DadosDeExemplo.popular(em: context)
        let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!
        if !grupo.pessoas.contains(where: { $0.nome == "Você" }) {
            _ = try? CRUD(context: context).criarPessoa(nome: "Você", grupo: grupo)
        }
        for comanda in try! context.fetch(FetchDescriptor<Comanda>()) { comanda.ativa = false }
    }()

    NavigationStack {
        CriarComandaView()
    }
    .modelContainer(container)
}

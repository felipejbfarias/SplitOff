//
//  SheetEditarGrupo.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//


import SwiftUI
import SwiftData
import PhotosUI

struct SheetEditarGrupo: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Bindable var grupo: Grupo

    @State private var fotoItem: PhotosPickerItem?
    @State private var fotoSelecionada: Data?

    @State private var nomeGrupo: String
    @State private var pessoasExistentes: [Pessoa]
    @State private var novasPessoas: [String] = []
    @State private var novoNomePessoa = ""

    @State private var mensagemErro: String?

    @State private var mostrarPopUpExcluir = false
    @State private var pessoaParaExcluir: Pessoa?

    @FocusState private var editando: Bool
    @State private var detente: PresentationDetent = .height(800)

    init(grupo: Grupo) {
        self.grupo = grupo
        _nomeGrupo = State(initialValue: grupo.nome)
        _fotoSelecionada = State(initialValue: grupo.foto)
        _pessoasExistentes = State(initialValue: grupo.pessoas)
    }

    private var podeSalvar: Bool {
        !nomeGrupo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
//                    PhotosPicker(selection: $fotoItem, matching: .images) {
//                        fotoGrupo
//                    }
                    fotoGrupo
//
//                    PhotosPicker(selection: $fotoItem, matching: .images) {
//                        Text("Alterar Foto")
//                            .foregroundStyle(.primary)
//                    }
//                    .buttonStyle(.bordered)
//                    .tint(.secondary)

                    Form {
                        Section {
                            TextField("Nome do Grupo", text: $nomeGrupo)
                                .focused($editando)
                        }

                        Section("Membros") {
                            ForEach(pessoasExistentes, id: \.id) { pessoa in
                                Text(pessoa.nome)
                            }
                            .onDelete { indexSet in
                                guard let index = indexSet.first else { return }

                                let pessoa = pessoasExistentes[index]

                                if pessoa.nome == CRUD.nomeVoce {
                                    mensagemErro = "O \"Você\" não pode ser removido."
                                    return
                                }

                                pessoaParaExcluir = pessoa
                                mostrarPopUpExcluir = true
                            }

                            ForEach(novasPessoas, id: \.self) { nome in
                                Text(nome)
                            }
                            .onDelete { indexSet in
                                novasPessoas.remove(atOffsets: indexSet)
                            }

                            TextField("Adicionar pessoa", text: $novoNomePessoa)
                                .focused($editando)
                                .onSubmit {
                                    adicionarPessoaTemporaria()
                                }
                        }
                        .font(.system(size: 17, weight: .regular))

                        if let mensagemErro {
                            Section {
                                Text(mensagemErro)
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    .padding(-10)
                }
                .navigationTitle("Editar Grupo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fechar", systemImage: "xmark") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Salvar", systemImage: "checkmark", action: salvarGrupo)
                            .disabled(!podeSalvar)
                            .tint(.accentColor)
                    }
                }
            }

            if mostrarPopUpExcluir, let pessoaParaExcluir {
                PopUPDestrutivo(
                    titulo: "Remover \(pessoaParaExcluir.nome)?",
                    mensagem: "Essa pessoa será removida do grupo.",
                    textoBotao: "Remover",
                    aoConfirmar: {
                        removerPessoaConfirmada(pessoaParaExcluir)
                    },
                    aoCancelar: {
                        mostrarPopUpExcluir = false
                        self.pessoaParaExcluir = nil
                    }
                )
            }
        }
        .presentationDetents([.height(800), .large], selection: $detente)
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemGroupedBackground))
        .onChange(of: editando) { _, ativo in
            detente = ativo ? .large : .height(800)
        }
        .onChange(of: fotoItem) { _, novoItem in
            Task {
                if let data = try? await novoItem?.loadTransferable(type: Data.self) {
                    fotoSelecionada = data
                }
            }
        }
    }

    private var fotoGrupo: some View {
        Group {
            if let fotoSelecionada,
               let uiImage = UIImage(data: fotoSelecionada) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 180, height: 180)
        .clipShape(Circle())
    }

    private func adicionarPessoaTemporaria() {
        let nomeTratado = novoNomePessoa.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !nomeTratado.isEmpty else { return }

        guard nomeTratado != CRUD.nomeVoce,
              !novasPessoas.contains(nomeTratado),
              !pessoasExistentes.contains(where: { $0.nome == nomeTratado }) else {
            novoNomePessoa = ""
            return
        }

        novasPessoas.append(nomeTratado)
        novoNomePessoa = ""
    }

    private func removerPessoaConfirmada(_ pessoa: Pessoa) {
        let crud = CRUD(context: context)

        do {
            try crud.removerPessoa(pessoa)
            pessoasExistentes.removeAll { $0.id == pessoa.id }

            mostrarPopUpExcluir = false
            pessoaParaExcluir = nil
        } catch {
            mensagemErro = error.localizedDescription
        }
    }

    private func salvarGrupo() {
        adicionarPessoaTemporaria()

        let crud = CRUD(context: context)

        do {
            grupo.foto = fotoSelecionada
            try crud.atualizarGrupo(grupo, nome: nomeGrupo)

            for nome in novasPessoas {
                try crud.criarPessoa(nome: nome, grupo: grupo)
            }

            dismiss()
        } catch {
            mensagemErro = error.localizedDescription
        }
    }
}

#Preview {
    @Previewable @State var mostrar = false

    let context = DadosDeExemplo.container.mainContext
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!

    NavigationStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }
    .task {
        mostrar = true
    }
    .sheet(isPresented: $mostrar) {
        SheetEditarGrupo(grupo: grupo)
    }
    .modelContainer(DadosDeExemplo.container)
}

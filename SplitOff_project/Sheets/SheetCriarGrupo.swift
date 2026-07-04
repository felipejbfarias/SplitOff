//
//  SheetCriarGrupo.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//


import SwiftUI
import SwiftData
import PhotosUI

// Sheet curto para adicionar um grupo. Grava via CRUD.criarGrupo.
struct SheetCriarGrupo: View {
    // Avisa quem apresentou qual grupo nasceu (ex.: para já selecionar no picker).
    let aoCriar: ((Grupo) -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var fotoItem: PhotosPickerItem?
    @State private var fotoSelecionada: Data?

    @State private var nomeGrupo = ""
    // Só os nomes: as Pessoas de verdade nascem pelo CRUD na hora de salvar.
    @State private var pessoas: [String] = []
    @State private var novoNomePessoa = ""
    @State private var mensagemErro: String?

    @FocusState private var editando: Bool
    @State private var detente: PresentationDetent = .height(800)

    init(aoCriar: ((Grupo) -> Void)? = nil) {
        self.aoCriar = aoCriar
    }


    // Só habilita criar com nome preenchido e preço válido.
    private var podeCriar: Bool {
        let grupoValido = !nomeGrupo
            .trimmingCharacters(in: .whitespaces)
            .isEmpty

        let possuiMembro = !pessoas.isEmpty ||
            !novoNomePessoa.trimmingCharacters(in: .whitespaces).isEmpty

        return grupoValido && possuiMembro
    }

    var body: some View {
        NavigationStack {
            VStack() {
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
                PhotosPicker(
                    selection: $fotoItem,
                    matching: .images
                ) {
                    Text("Adicionar Foto")
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                Form {
                    Section {
                        TextField("Nome do Grupo", text: $nomeGrupo)
                            .focused($editando)
                    }
                    Section("Membros") {
                        // "Você" entra automático em todo grupo criado.
                        Text("Você")
                            .foregroundStyle(.secondary)

                        ForEach(pessoas, id: \.self) { nome in
                            Text(nome)
                        }
                        .onDelete { indexSet in
                            pessoas.remove(atOffsets: indexSet)
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
            .navigationTitle("Criar Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar", systemImage: "checkmark", action: criarGrupo)
                        .disabled(!podeCriar)
                        .tint(.accentColor)
                }
            }
        }
        
        // Abre curto e expande para .large enquanto o campo está em foco.
        .presentationDetents([.height(800), .large], selection: $detente)
        .presentationDragIndicator(.visible)
        // Fundo opaco fixo para o detent curto não ficar translúcido/cinza.
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

    // Guarda o nome digitado na lista de membros pendentes.
    private func adicionarPessoaTemporaria() {
        let nomeTratado = novoNomePessoa.trimmingCharacters(in: .whitespaces)

        guard !nomeTratado.isEmpty else { return }

        guard !pessoas.contains(nomeTratado), nomeTratado != "Você" else {
            novoNomePessoa = ""
            return
        }

        pessoas.append(nomeTratado)
        novoNomePessoa = ""
    }

    // Cria o grupo e as pessoas pelo CRUD e fecha o sheet.
    private func criarGrupo() {
        adicionarPessoaTemporaria()

        let crud = CRUD(context: context)

        do {
            let grupo = try crud.criarGrupo(nome: nomeGrupo, foto: fotoSelecionada)

            for nome in pessoas {
                try crud.criarPessoa(nome: nome, grupo: grupo)
            }

            aoCriar?(grupo)
            dismiss()
        } catch {
            mensagemErro = error.localizedDescription
        }
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
        SheetCriarGrupo()
    }
    .modelContainer(DadosDeExemplo.container)
}


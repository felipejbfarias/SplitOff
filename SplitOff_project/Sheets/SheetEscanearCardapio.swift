//
//  SheetEscanearCardapio.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 12/07/26.
//

import SwiftUI
import SwiftData
import PhotosUI

// Escaneia um cardápio a partir de uma foto, o OCR lê o texto
// o Apple Intelligence estrutura os itens e o usuário revisa antes de gravar.
struct SheetEscanearCardapio: View {
    enum Fonte: String, Identifiable {
        case camera, galeria
        var id: String { rawValue }
    }

    private enum Etapa {
        case capturando, processando, revisao, falha
    }

    // Item extraído em revisão, o usuário pode corrigir nome/preço e desmarcar.
    private struct LinhaEscaneada: Identifiable {
        let id: UUID
        var nome: String
        var precoTexto: String
        var incluido: Bool
        var jaExiste: Bool

        var preco: Decimal? {
            Decimal(string: precoTexto.replacingOccurrences(of: ",", with: "."))
        }

        var valida: Bool {
            !nome.trimmingCharacters(in: .whitespaces).isEmpty && (preco ?? -1) >= 0
        }
    }

    // Cardápio que recebe os itens escaneados.
    let cardapio: Cardapio
    let fonte: Fonte

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var etapa: Etapa = .capturando
    @State private var mostrarCamera = false
    @State private var mostrarGaleria = false
    @State private var itemGaleria: PhotosPickerItem?
    @State private var linhas: [LinhaEscaneada] = []
    @State private var mensagemErro = ""

    // O modelo ainda está gerando itens
    @State private var aindaEscaneando = false
    @State private var tarefaExtracao: Task<Void, Never>?

    private var selecionadas: [LinhaEscaneada] {
        linhas.filter { $0.incluido && $0.valida }
    }

    var body: some View {
        NavigationStack {
            conteudo
                .navigationTitle("Escanear cardápio")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fechar", systemImage: "xmark") { dismiss() }
                    }
                }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $mostrarCamera) {
            CameraPicker { imagem in
                processar(imagem)
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $mostrarGaleria, selection: $itemGaleria, matching: .images)
        .onAppear(perform: abrirFonte)
        .onDisappear { tarefaExtracao?.cancel() }
        // Fechou a câmera/galeria sem foto ainda na captura
        .onChange(of: mostrarCamera) { _, aberta in
            if !aberta && etapa == .capturando { dismiss() }
        }
        .onChange(of: mostrarGaleria) { _, aberta in
            if !aberta && etapa == .capturando && itemGaleria == nil { dismiss() }
        }
        .onChange(of: itemGaleria) { _, item in
            guard let item else { return }
            etapa = .processando
            Task {
                if let dados = try? await item.loadTransferable(type: Data.self),
                   let imagem = UIImage(data: dados) {
                    processar(imagem)
                } else {
                    mostrarFalha(ScannerCardapioErro.imagemInvalida.localizedDescription)
                }
            }
        }
    }

    @ViewBuilder
    private var conteudo: some View {
        switch etapa {
        case .capturando:
            Color.clear
        case .processando:
            processando
        case .revisao:
            revisao
        case .falha:
            falha
        }
    }

    private var processando: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.pink)
                .symbolEffect(.pulse)

            Text("Lendo o cardápio…")
                .font(.title3.weight(.semibold))

            Text(
                ExtratorItensCardapio.inteligenciaDisponivel
                    ? "A Apple Intelligence está organizando os itens e preços."
                    : "Organizando os itens e preços da foto."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            ProgressView()
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var revisao: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    ForEach($linhas) { $linha in
                        linhaRevisao($linha)
                    }
                } header: {
                    Text(linhas.count == 1 ? "1 item encontrado" : "\(linhas.count) itens encontrados")
                } footer: {
                    if aindaEscaneando {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Procurando mais itens…")
                        }
                    } else {
                        Text("Confira os nomes e preços antes de adicionar. Toque para corrigir.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .animation(.snappy, value: linhas.count)

            botaoAdicionar
                .padding(.bottom, 12)
        }
    }

    private func linhaRevisao(_ linha: Binding<LinhaEscaneada>) -> some View {
        HStack(spacing: 12) {
            Button {
                linha.wrappedValue.incluido.toggle()
            } label: {
                Image(systemName: linha.wrappedValue.incluido ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(linha.wrappedValue.incluido ? Color.accentColor : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                TextField("Nome do item", text: linha.nome)
                    .font(.body)

                HStack(spacing: 4) {
                    Text("R$")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("Preço", text: linha.precoTexto)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .keyboardType(.decimalPad)
                }

                if linha.wrappedValue.jaExiste {
                    Text("Já existe no cardápio")
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .opacity(linha.wrappedValue.incluido ? 1 : 0.5)
    }

    @ViewBuilder
    private var botaoAdicionar: some View {
        let quantidade = selecionadas.count
        let titulo = quantidade == 1 ? "Adicionar 1 item" : "Adicionar \(quantidade) itens"

        if quantidade > 0 {
            Button(action: adicionar) {
                Text(titulo)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.glassProminent)
            .tint(.pink)
            .padding(12)
        } else {
            Button {} label: {
                Text("Adicionar itens")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.glass)
            .allowsHitTesting(false)
            .padding(12)
        }
    }

    private var falha: some View {
        VStack(spacing: 20) {
            ContentUnavailableView(
                "Não deu pra ler o cardápio",
                systemImage: "text.viewfinder",
                description: Text(mensagemErro)
            )
            .frame(maxHeight: 320)

            Button {
                etapa = .capturando
                itemGaleria = nil
                abrirFonte()
            } label: {
                Text("Tentar outra foto")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.glassProminent)
            .tint(.pink)
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func abrirFonte() {
        switch fonte {
        case .camera: mostrarCamera = true
        case .galeria: mostrarGaleria = true
        }
    }

    private func processar(_ imagem: UIImage) {
        etapa = .processando
        aindaEscaneando = true
        tarefaExtracao = Task {
            do {
                // Os snapshots do streaming vão preenchendo a revisão em tempo real;
                let itens = try await ExtratorItensCardapio.extrair(de: imagem) { parciais in
                    atualizarLinhas(com: parciais)
                    if !linhas.isEmpty { etapa = .revisao }
                }
                atualizarLinhas(com: itens)
                etapa = .revisao
            } catch is CancellationError {
                // Sheet fechado ou itens adicionados no meio da geração: nada a fazer.
            } catch {
                mostrarFalha(error.localizedDescription)
            }
            aindaEscaneando = false
        }
    }

    // Sincroniza a revisão com um snapshot do extrator, sem recriar as linhas
    private func atualizarLinhas(com itens: [ItemEscaneado]) {
        let atuais = Dictionary(uniqueKeysWithValues: linhas.map { ($0.id, $0) })
        let nomesNoCardapio = Set(cardapio.itens.map { ExtratorItensCardapio.chaveDoNome($0.nome) })

        linhas = itens.map { item in
            if let linha = atuais[item.id] { return linha }

            let jaExiste = nomesNoCardapio.contains(ExtratorItensCardapio.chaveDoNome(item.nome))
            return LinhaEscaneada(
                id: item.id,
                nome: item.nome,
                precoTexto: item.preco.formatted(.number.locale(Locale(identifier: "pt_BR")).grouping(.never)),
                incluido: !jaExiste,
                jaExiste: jaExiste
            )
        }
    }

    private func mostrarFalha(_ mensagem: String) {
        mensagemErro = mensagem
        etapa = .falha
    }

    // Grava os itens marcados no cardápio via CRUD e fecha.
    private func adicionar() {
        tarefaExtracao?.cancel()
        let crud = CRUD(context: context)
        for linha in selecionadas {
            _ = try? crud.criarItem(nome: linha.nome, preco: linha.preco ?? 0, cardapio: cardapio)
        }
        dismiss()
    }
}

#Preview {
    @Previewable @State var mostrar = false
    let context = DadosDeExemplo.container.mainContext
    let cardapio = try! context.fetch(FetchDescriptor<Cardapio>()).first!

    NavigationStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }
    .task { mostrar = true }
    .sheet(isPresented: $mostrar) {
        SheetEscanearCardapio(cardapio: cardapio, fonte: .galeria)
    }
    .modelContainer(DadosDeExemplo.container)
}

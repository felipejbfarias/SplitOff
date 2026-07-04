//
//  ItensDividirView.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Etapa 3 do novo pedido: escolher quais itens serão divididos e com quem, e registrar a rodada completa
struct ItensDividirView: View {
    let comanda: Comanda
    let autor: ParticipanteComanda

    // Itens e quantidades escolhidos na tela de cardápio.
    let escolhas: [LinhaStepper]

    var aoConcluir: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var linhas: [LinhaSeletorStepper] = []
    @State private var linhaParaDividir: LinhaSeletorStepper?
    @State private var mensagemErro: String?

    // Com quem dá para dividir: todos da comanda menos o autor do pedido.
    private var outrosParticipantes: [ParticipanteComanda] {
        comanda.participantes
            .filter { $0 != autor }
            .sorted {
                if $0.nomePessoa == "Você" { return true }
                if $1.nomePessoa == "Você" { return false }
                return $0.nomePessoa < $1.nomePessoa
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar()

            Text("Divisão")
                .font(.system(size: 34, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)

            BarraProgresso(etapa: .itensDividir)
                .padding(.horizontal)
                .padding(.top, 28)

            ScrollView {
                VStack(spacing: 20) {
                    Text("Vai dividir algum item?")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.tertiary)

                    ListaRowsSeletorStepper(linhas: $linhas, aoSelecionar: alternarDivisao)

                    if let mensagemErro {
                        Text(mensagemErro)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .padding(.top, 12)
            }

            BotaoSimples1(titulo: "Concluir Pedido", acao: concluirPedido)
                .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: montarLinhas)
        .sheet(item: $linhaParaDividir) { linha in
            SheetSelecionarPessoas(
                modo: .dividir(autor: autor.nomePessoa, item: linha.nome),
                pessoas: outrosParticipantes,
                nome: \.nomePessoa
            ) { selecionados in
                definirDonos(de: linha, para: selecionados)
            }
        }
    }

    // Uma linha por item escolhido; o máximo divisível é a quantidade pedida.
    private func montarLinhas() {
        guard linhas.isEmpty else { return }
        linhas = escolhas.map {
            LinhaSeletorStepper(id: $0.id, item: $0.item, donos: [], quantidade: 0, quantidadeMaxima: $0.quantidade)
        }
    }

    // Marcar abre o sheet de pessoas; desmarcar limpa a divisão do item.
    private func alternarDivisao(_ linha: LinhaSeletorStepper) {
        if linha.selecionado {
            atualizar(linha.id) {
                $0.donos = []
                $0.quantidade = 0
            }
        } else {
            linhaParaDividir = linha
        }
    }

    private func definirDonos(de linha: LinhaSeletorStepper, para selecionados: [ParticipanteComanda]) {
        atualizar(linha.id) { $0.donos = selecionados }
    }

    private func atualizar(_ id: UUID, _ mudanca: (inout LinhaSeletorStepper) -> Void) {
        guard let indice = linhas.firstIndex(where: { $0.id == id }) else { return }
        mudanca(&linhas[indice])
    }

    // Registra a rodada no backend: unidades não divididas ficam só com o autor, as divididas somam o autor e os donos escolhidos no sheet.
    private func concluirPedido() {
        let crud = CRUD(context: modelContext)

        do {
            let pedido = try crud.criarPedido(comanda: comanda)

            for linha in linhas {
                let divididas = linha.prontoParaCRUD ? linha.quantidade : 0
                let sozinhas = linha.quantidadeMaxima - divididas

                if sozinhas > 0 {
                    try crud.criarItemPedido(
                        itemCardapio: linha.item,
                        quantidade: sozinhas,
                        pedido: pedido,
                        donos: [autor]
                    )
                }

                if divididas > 0 {
                    try crud.criarItemPedido(
                        itemCardapio: linha.item,
                        quantidade: divididas,
                        pedido: pedido,
                        donos: [autor] + linha.donos
                    )
                }
            }

            if let aoConcluir {
                aoConcluir()
            } else {
                dismiss()
            }
        } catch {
            mensagemErro = error.localizedDescription
        }
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let crud = CRUD(context: context)
    let comanda = try! context.fetch(FetchDescriptor<Comanda>()).first { $0.ativa }!

    // Participantes extras para o sheet de divisão ter opções além do autor.
    let _ = {
        for nome in ["Você", "Matheus", "Felipe", "Davi"] where !comanda.participantes.contains(where: { $0.nomePessoa == nome }) {
            guard let grupo = comanda.grupo else { return }
            let pessoa = grupo.pessoas.first { $0.nome == nome } ?? (try! crud.criarPessoa(nome: nome, grupo: grupo))
            _ = try? crud.adicionarParticipante(pessoa, a: comanda)
        }
    }()

    let autor = comanda.participantes.first { $0.nomePessoa == "Você" }!
    let itens = try! context.fetch(FetchDescriptor<Item>())

    let escolhas = itens.prefix(3).enumerated().map { indice, item in
        LinhaStepper(id: item.id, item: item, quantidade: indice + 1)
    }

    NavigationStack {
        ItensDividirView(comanda: comanda, autor: autor, escolhas: Array(escolhas))
    }
    .modelContainer(DadosDeExemplo.container)
}

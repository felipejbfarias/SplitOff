//
//  ComandaAtualView.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Tem duas abas num segment control:
// Pedidos: as rodadas feitas, em ordem decrescente.
// Consumos: total, progresso do pagamento e a conta de cada participante.
struct ComandaAtualView: View {
    @Environment(\.modelContext) private var context
    @Environment(OverlayPresenter.self) private var overlay
    private enum Aba: String, CaseIterable {
        case pedidos = "Pedidos"
        case consumos = "Consumos"
    }

    // A única comanda ativa do app
    @Query(filter: #Predicate<Comanda> { $0.ativa }) private var comandasAtivas: [Comanda]

    @State private var aba: Aba = .pedidos
    @State private var mostrarPagamento = false
    @State private var mostrarNovoPedido = false
    @State private var mensagemErro: String?

    private var comanda: Comanda? { comandasAtivas.first }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if let comanda {
                conteudo(comanda)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // Fluxo de novo pedido: Escolher Pessoas -> Cardápio -> Divisão.
        .navigationDestination(isPresented: $mostrarNovoPedido) {
            if let comanda {
                EscolherPessoasView(comanda: comanda) {
                    mostrarNovoPedido = false
                }
            }
        }
    }

    // Layout principal quando existe uma comanda ativa.
    private func conteudo(_ comanda: Comanda) -> some View {
        VStack(spacing: 0) {
            TopBar(mostrarVoltar: false, simboloDireita: "plus") { adicionarPedido(comanda) }
                .opacity(aba == .pedidos ? 1 : 0)
                .disabled(aba != .pedidos)

            Text("Comanda Atual")
                .font(.system(size: 34, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)

            Picker("Aba", selection: $aba) {
                ForEach(Aba.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)

            if let mensagemErro {
                Text(mensagemErro)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            ScrollView {
                switch aba {
                    case .pedidos: abaPedidos(comanda)
                    case .consumos: abaConsumos(comanda)
                }
            }

            if aba == .consumos {
                rodape(comanda)
            }
        }
        .sheet(isPresented: $mostrarPagamento) {
            SheetPagamentoComanda(comanda: comanda)
        }
    }

    // 1 linha expansível por rodada, da mais recente para a mais antiga
    private func abaPedidos(_ comanda: Comanda) -> some View {
        LazyVStack(spacing: 16) {
            ForEach(comanda.pedidos.sorted { $0.numero > $1.numero }) { pedido in
                RowExpandivel(pedido: pedido)
            }
        }
        .padding()
    }

    // resumo do total, progresso do pagamento e a conta de cada participante.
    private func abaConsumos(_ comanda: Comanda) -> some View {
        LazyVStack(spacing: 16) {
            CardCustoTotal(comanda: comanda)
            CardProgresso(comanda: comanda)

            ForEach(participantesOrdenados(comanda)) { participante in
                if participante.valorPago > 0 || comanda.podeFechar {
                    RowExpandivel(contaPaga: participante)
                } else {
                    RowExpandivel(conta: participante)
                }
            }
        }
        .padding()
    }

    // Mesmo botão nas duas versões da aba: quando a comanda pode fechar ele encerra senão abre o pagamento.
    private func rodape(_ comanda: Comanda) -> some View {
        BotaoSimples1(titulo: comanda.podeFechar ? "Encerrar Comanda" : "Pagar") {
            if comanda.podeFechar {
                confirmarEncerramento(comanda)
            } else {
                mostrarPagamento = true
            }
        }
        .padding(.bottom, 12)
    }

    // Popup na raiz para escurecer a tela inteira
    private func confirmarEncerramento(_ comanda: Comanda) {
        overlay.mostrar(
            PopUPConfirmacao(
                titulo: "Encerrar Comanda",
                mensagem: "Ao encerrar, quem pagou a mais vira credor e quem pagou a menos vira devedor no grupo.",
                textoBotao: "Encerrar Comanda",
                aoConfirmar: {
                    overlay.esconder()
                    encerrarComanda(comanda)
                },
                aoCancelar: { overlay.esconder() }
            )
        )
    }

    

    // Você primeiro, depois em ordem alfabética
    private func participantesOrdenados(_ comanda: Comanda) -> [ParticipanteComanda] {
        comanda.participantes.sorted {
            if $0.nomePessoa == "Você" { return true }
            if $1.nomePessoa == "Você" { return false }
            return $0.nomePessoa < $1.nomePessoa
        }
    }

    // Abre o fluxo de nova rodada de pedido.
    private func adicionarPedido(_ comanda: Comanda) {
        mostrarNovoPedido = true
    }

    // Fecha a comanda e acerta os saldos do grupo.
    private func encerrarComanda(_ comanda: Comanda) {
        let crud = CRUD(context: context)

        do {
            try crud.fecharComanda(comanda)
        } catch {
            mensagemErro = error.localizedDescription
        }
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let comanda = (try? context.fetch(FetchDescriptor<Comanda>()))?.first { $0.ativa }

    // Adiciona algumas rodadas extras para ver a ordem decrescente na aba de pedidos.
    let _: Void = {
        guard let comanda, let participante = comanda.participantes.first else { return }
        let crud = CRUD(context: context)
        for _ in 0..<3 {
            if let pedido = try? crud.criarPedido(comanda: comanda) {
                _ = try? crud.criarItemPedido(nome: "Rodízio", preco: 40, pedido: pedido, donos: [participante])
            }
        }
    }()

    return NavigationStack {
        ComandaAtualView()
    }
    .environment(OverlayPresenter())
    .modelContainer(DadosDeExemplo.container)
}

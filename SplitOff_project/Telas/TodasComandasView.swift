//
//  TodasComandasView.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Histórico de todas as comandas
struct TodasComandasView: View {
    @Query(sort: \Comanda.data, order: .reverse) private var comandas: [Comanda]

    @Environment(\.modelContext) private var modelContext

    @State private var mostrarCriarComanda = false
    @State private var comandaParaApagar: Comanda?
    @State private var comandaDetalhe: Comanda?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                TopBar(mostrarVoltar: false, simboloDireita: "magnifyingglass") {}
                    .hidden()

                Text("SplitOff")
                    .font(.system(size: 34, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                if comandas.isEmpty {
                    semComandas
                } else {
                    listaComandas
                }

                BotaoSimples1(titulo: "Nova comanda") { mostrarCriarComanda = true }
                    .padding(.bottom, 12)
            }

            // Confirmação antes de remover uma comanda do histórico.
            if let comanda = comandaParaApagar {
                PopUPDestrutivo.apagarComanda(comanda) {
                    try? CRUD(context: modelContext).removerComanda(comanda)
                    comandaParaApagar = nil
                } aoCancelar: {
                    comandaParaApagar = nil
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $mostrarCriarComanda) {
            CriarComandaView()
        }
        // Detalhamento da comanda tocada no histórico.
        .sheet(item: $comandaDetalhe) { comanda in
            SheetHistoricoRole(comanda: comanda)
        }
    }

    // Estado vazi;o
    private var semComandas: some View {
        VStack(spacing: 28) {
            Image("maca_cortada")
                .resizable()
                .scaledToFit()
                .frame(width: 240)

            Text("Crie sua primeira comanda")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Histórico em 3 linha
    private var listaComandas: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(comandas) { comanda in
                    RowGrupoHistorico(comanda: comanda, incluirGrupo: true) {
                        comandaDetalhe = comanda
                    } aoRemover: {
                        comandaParaApagar = comanda
                    }
                }
            }
            .padding()
        }
    }
}

#Preview("Vazia") {
    let schema = Schema(splitOffModels)
    let configuracao = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuracao])

    NavigationStack {
        TodasComandasView()
    }
    .modelContainer(container)
}

#Preview("Com comandas") {
    let schema = Schema(splitOffModels)
    let configuracao = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuracao])
    let context = container.mainContext

    let _ = {
        DadosDeExemplo.popular(em: context)
        let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!
        let pessoas = Array(grupo.pessoas.prefix(3))
        for comanda in try! context.fetch(FetchDescriptor<Comanda>()) { comanda.ativa = false }

        func criarComandaHistorica(
            nome: String,
            lugar: String,
            diasAtras: TimeInterval,
            todosQuitaram: Bool
        ) {
            let restaurante = Restaurante(nome: lugar, cardapio: Cardapio(nome: "Cardápio"))
            let comanda = Comanda(
                nome: nome,
                data: Date.now.addingTimeInterval(-diasAtras * 86_400),
                ativa: false,
                restaurante: restaurante,
                grupo: grupo
            )
            context.insert(comanda)

            let participantes = pessoas.map { pessoa in
                let participante = ParticipanteComanda(pessoa: pessoa, comanda: comanda)
                context.insert(participante)
                return participante
            }

            let pedido = Pedido(numero: 1, comanda: comanda)
            context.insert(pedido)

            let itemPrincipal = ItemPedido(nome: "Rodízio", preco: 150, donos: participantes)
            itemPrincipal.pedido = pedido
            context.insert(itemPrincipal)

            if let primeiro = participantes.first {
                let bebida = ItemPedido(nome: "Bebidas", preco: 45, donos: [primeiro])
                bebida.pedido = pedido
                context.insert(bebida)
            }

            for (indice, participante) in participantes.enumerated() {
                if todosQuitaram {
                    participante.valorPago = participante.contaAtual
                } else {
                    participante.valorPago = indice == 0 ? participante.contaAtual : participante.contaAtual / 2
                }
            }
        }

        criarComandaHistorica(nome: "Aniversário de PA", lugar: "Bar do Pinto", diasAtras: 16, todosQuitaram: true)
        criarComandaHistorica(nome: "Pós Ponte", lugar: "Muamba", diasAtras: 40, todosQuitaram: false)
    }()

    NavigationStack {
        TodasComandasView()
    }
    .modelContainer(container)
}

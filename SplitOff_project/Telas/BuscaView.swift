//
//  BuscaView.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Busca no histórico de comandas fechadas, por nome do lugar ou pelo valor que o Você gastou.
struct BuscaView: View {
    @Query private var comandas: [Comanda]

    @State private var modo: ModoBusca = .nome
    @State private var buscaNome = ""
    @State private var buscaValor: Decimal = 0
    @State private var resultados: [Comanda] = []
    @State private var comandaSelecionada: Comanda?

    private var buscaVazia: Bool {
        switch modo {
            case .nome: buscaNome.trimmingCharacters(in: .whitespaces).isEmpty
            case .valor: buscaValor == 0
        }
    }

    // O que os cards destacam em accent, conforme o modo ativo.
    private var destaque: DestaqueBusca {
        modo == .nome ? .nome(buscaNome) : (buscaValor > 0 ? .valor : .nenhum)
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(mostrarVoltar: false, simboloDireita: "magnifyingglass") {}
                .hidden()

            Text("Comandas")
                .font(.system(size: 34, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)

            if buscaVazia {
                lupaGigante
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(resultados) { comanda in
                            Button {
                                comandaSelecionada = comanda
                            } label: {
                                CardComandaBusca(comanda: comanda, destaque: destaque)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            // Sempre presente na aba de busca; ele abre o teclado sozinho ao aparecer
            // e o X (com a busca vazia) só recolhe o teclado.
            FiltrosBusca(
                comandas: comandas,
                modo: $modo,
                buscaNome: $buscaNome,
                buscaValor: $buscaValor,
                resultados: $resultados
            )
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(item: $comandaSelecionada) { comanda in
            SheetHistoricoRole(comanda: comanda)
        }
    }

    private var lupaGigante: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 96, weight: .bold))
                .foregroundStyle(Color.accentColor)

            Text("Busque o seu restaurante pelo nome\nou preço que quer gastar")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let crud = CRUD(context: context)
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!

    // Você e duas comandas fechadas em lugares diferentes.
    let _ = {
        let voce = grupo.pessoas.first { $0.nome == "Você" }
            ?? (try! crud.criarPessoa(nome: "Você", grupo: grupo))

        guard !grupo.comandas.contains(where: { !$0.ativa }) else { return }

        let mamute = Restaurante(nome: "Mamute", cardapio: Cardapio(nome: "Cardápio"))
        let comandaMamute = Comanda(nome: "Rolê de sábado", ativa: false, restaurante: mamute, grupo: grupo)
        context.insert(comandaMamute)
        let voceNoMamute = ParticipanteComanda(pessoa: voce, comanda: comandaMamute)
        let pedidoMamute = Pedido(numero: 1, comanda: comandaMamute)
        let itemMamute = ItemPedido(nome: "Parmegiana", preco: 36, donos: [voceNoMamute])
        itemMamute.pedido = pedidoMamute

        let barDoPinto = Restaurante(nome: "Bar do Pinto", cardapio: Cardapio(nome: "Cardápio"))
        let comandaBar = Comanda(nome: "Happy hour", ativa: false, restaurante: barDoPinto, grupo: grupo)
        context.insert(comandaBar)
        let voceNoBar = ParticipanteComanda(pessoa: voce, comanda: comandaBar)
        let pedidoBar = Pedido(numero: 1, comanda: comandaBar)
        let itemBar = ItemPedido(nome: "Petisco", preco: 20, donos: [voceNoBar])
        itemBar.pedido = pedidoBar
    }()

    NavigationStack {
        BuscaView()
    }
    .modelContainer(DadosDeExemplo.container)
}

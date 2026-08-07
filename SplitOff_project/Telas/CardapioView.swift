//
//  CardapioView.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Etapa 2 do novo pedido: marcar os itens do cardápio e as quantidades da rodada.
struct CardapioView: View {
    let comanda: Comanda
    let autor: ParticipanteComanda
    var aoConcluir: (() -> Void)? = nil

    @State private var linhas: [LinhaStepper] = []
    @State private var mostrarEditar = false
    @State private var irParaDivisao = false
    @State private var busca = ""

    private var cardapio: Cardapio? {
        comanda.restaurante?.cardapio
    }

    // Itens com quantidade escolhida, que seguem para a divisão.
    private var escolhidos: [LinhaStepper] {
        linhas.filter(\.incluso)
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar(simboloDireita: cardapio == nil ? nil : "pencil") { mostrarEditar = true }

            Text("Cardápio")
                .font(.system(size: 34, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)

            BarraProgresso(etapa: .cardapio)
                .padding(.horizontal)
                .padding(.top, 28)

            if let cardapio {
                campoBusca
                    .padding(.horizontal)
                    .padding(.top, 16)

                ScrollView {
                    ListaRowsStepper(linhas: $linhas, cardapio: cardapio, filtro: busca)
                        .padding()
                        .padding(.top, 4)
                }

                BotaoSimples1(titulo: "Encerrar Seleção") { irParaDivisao = true }
                    .disabled(escolhidos.isEmpty)
                    .padding(.bottom, 12)
            } else {
                ContentUnavailableView(
                    "Comanda sem cardápio",
                    systemImage: "menucard",
                    description: Text("Essa comanda não tem um lugar com cardápio associado.")
                )
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: montarLinhas)
        .onChange(of: cardapio?.itens.count) { montarLinhas() }
        .sheet(isPresented: $mostrarEditar) {
            if let cardapio {
                SheetEditarCardapio(cardapio: cardapio)
            }
        }
        .navigationDestination(isPresented: $irParaDivisao) {
            ItensDividirView(comanda: comanda, autor: autor, escolhas: escolhidos, aoConcluir: aoConcluir)
        }
    }

    // Busca para cardápios grandes
    private var campoBusca: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Buscar no cardápio", text: $busca)

            if !busca.isEmpty {
                Button {
                    busca = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: .capsule)
    }

    private func montarLinhas() {
        let quantidades = Dictionary(uniqueKeysWithValues: linhas.map { ($0.id, $0.quantidade) })
        let itens = (cardapio?.itens ?? []).sorted { $0.nome < $1.nome }
        linhas = itens.map { LinhaStepper(id: $0.id, item: $0, quantidade: quantidades[$0.id] ?? 0) }
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let comanda = try! context.fetch(FetchDescriptor<Comanda>()).first { $0.ativa }!
    let autor = comanda.participantes.first!

    NavigationStack {
        CardapioView(comanda: comanda, autor: autor)
    }
    .modelContainer(DadosDeExemplo.container)
}

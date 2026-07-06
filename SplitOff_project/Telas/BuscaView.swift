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
    @State private var textoBusca = ""
    @State private var comandaSelecionada: Comanda?

    // A busca cobre só o histórico: a comanda ativa fica de fora.
    private var comandasFechadas: [Comanda] {
        comandas.filter { !$0.ativa }
    }

    private var valorBuscado: Decimal {
        let numerico = textoBusca
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }
        return Decimal(string: numerico) ?? 0
    }

    private var buscaVazia: Bool {
        switch modo {
            case .nome: textoBusca.trimmingCharacters(in: .whitespaces).isEmpty
            case .valor: valorBuscado == 0
        }
    }

    private var resultados: [Comanda] {
        switch modo {
            case .nome:
                let busca = textoBusca.trimmingCharacters(in: .whitespaces)
                return busca.isEmpty ? comandasFechadas : comandasFechadas.filter {
                    nomeDoLugar($0).localizedStandardContains(busca)
                }
            case .valor:
                return valorBuscado == 0 ? comandasFechadas : comandasFechadas.filter {
                    guard let gasto = $0.gastoDoVoce else { return false }
                    return gasto <= valorBuscado
                }
        }
    }

    // O que os cards destacam em accent, conforme o modo ativo.
    private var destaque: DestaqueBusca {
        modo == .nome ? .nome(textoBusca) : (valorBuscado > 0 ? .valor : .nenhum)
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
            SeletorModoBusca(modo: $modo)
        }
        .searchable(
            text: $textoBusca,
            prompt: modo == .nome ? "Buscar lugar" : "Valor máximo que você gastou"
        )
        .keyboardType(modo == .valor ? .decimalPad : .default)
        .sheet(item: $comandaSelecionada) { comanda in
            SheetHistoricoRole(comanda: comanda)
        }
    }

    // Nome exibido do lugar da comanda, igual aos títulos do app.
    private func nomeDoLugar(_ comanda: Comanda) -> String {
        comanda.restaurante?.nome ?? comanda.nome
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

private struct SeletorModoBusca: View {
    @Binding var modo: ModoBusca
    @Environment(\.isSearching) private var buscando

    var body: some View {
        if buscando {
            GlassEffectContainer(spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(ModoBusca.allCases, id: \.self) { opcao in
                        Button {
                            withAnimation(.snappy) { modo = opcao }
                        } label: {
                            Image(systemName: opcao.simbolo)
                                .font(.subheadline.weight(modo == opcao ? .semibold : .regular))
                                .foregroundStyle(modo == opcao ? Color.white : .secondary)
                                .frame(width: 52, height: 40)
                                .glassEffect(
                                    modo == opcao ? .regular.tint(Color.accentColor) : .regular,
                                    in: .capsule
                                )
                                .contentShape(.capsule)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            // O campo de busca do sistema flutua sobre essa área;
            // o respiro levanta as pills para cima dele.
            .padding(.bottom, 72)
        }
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

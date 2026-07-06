//
//  FiltrosBusca.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Modo de busca: pelo nome do lugar ou pelo que o você gastou
enum ModoBusca: String, CaseIterable {
    case nome = "Nome"
    case valor = "Valor"

    // Símbolo mostrado
    var simbolo: String {
        switch self {
            case .nome: "textformat"
            case .valor: "brazilianrealsign"
        }
    }
}

// Filtro de busca ancorado acima do teclado.
struct FiltrosBusca: View {
    let comandas: [Comanda]
    @Binding var modo: ModoBusca
    @Binding var buscaNome: String
    @Binding var buscaValor: Decimal
    @Binding var resultados: [Comanda]
    var aoFechar: (() -> Void)? = nil

    @State private var valorTexto = ""
    @State private var valorEmCentavos = 0
    @FocusState private var foco: ModoBusca?

    // Valor digitado no teclado numérico
    private var valor: Decimal {
        Decimal(valorEmCentavos) / 100
    }

    private var buscaVazia: Bool {
        modo == .nome ? buscaNome.isEmpty : valorEmCentavos == 0
    }

    // A busca cobre só o histórico: a comanda ativa fica de fora.
    private var comandasFechadas: [Comanda] {
        comandas.filter { !$0.ativa }
    }

    var body: some View {
        VStack(spacing: 12) {
            seletorModo

            // A busca por nome é digitada no campo nativo da tab bar
            if modo == .valor {
                campoBusca
            }
        }
        .onAppear {
            atualizarResultados()
        }
        .onChange(of: modo) {
            atualizarResultados()
            Task { foco = modo == .valor ? .valor : nil }
        }
        .onChange(of: buscaNome) { atualizarResultados() }
        .onChange(of: valorTexto) {
            let digitos = String(valorTexto.filter(\.isNumber).prefix(8))
            if digitos != valorTexto { valorTexto = digitos }
            valorEmCentavos = Int(digitos) ?? 0
            buscaValor = valor
            atualizarResultados()
        }
        .onChange(of: comandas) { atualizarResultados() }
    }
    
    // O modo ativo fica pintado
    private var seletorModo: some View {
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
    }

    // Campo de busca com lupa e botão de fechar ao lado.
    private var campoBusca: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                campoValor
            }
            .frame(height: 22)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: .capsule)

            Button {
                if buscaVazia {
                    foco = nil
                    aoFechar?()
                } else {
                    limpar()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.secondarySystemGroupedBackground), in: .circle)
            }
            .buttonStyle(.plain)
        }
    }

    // Valor em reais
    private var campoValor: some View {
        Text(valorEmCentavos == 0 ? "R$ 0,00" : valor.formatted(.currency(code: "BRL")))
            .foregroundStyle(valorEmCentavos == 0 ? .secondary : .primary)
            .contentTransition(.numericText())
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .background {
                TextField("", text: $valorTexto)
                    .keyboardType(.numberPad)
                    .focused($foco, equals: .valor)
                    .opacity(0)
            }
            .onTapGesture { foco = .valor }
    }

    // Nome exibido do lugar da comanda, igual aos títulos do app.
    private func nomeDoLugar(_ comanda: Comanda) -> String {
        comanda.restaurante?.nome ?? comanda.nome
    }

    // Busca vazia devolve todas as fechadas
    private func atualizarResultados() {
        switch modo {
            case .nome:
                let busca = buscaNome.trimmingCharacters(in: .whitespaces)
                resultados = busca.isEmpty ? comandasFechadas : comandasFechadas.filter {
                    nomeDoLugar($0).localizedStandardContains(busca)
                }
            case .valor:
                resultados = valorEmCentavos == 0 ? comandasFechadas : comandasFechadas.filter {
                    guard let gasto = $0.gastoDoVoce else { return false }
                    return gasto <= valor
                }
        }
    }

    private func limpar() {
        withAnimation(.snappy) {
            buscaNome = ""
            valorTexto = ""
        }
    }
}

#Preview {
    @Previewable @State var modo: ModoBusca = .nome
    @Previewable @State var buscaNome = ""
    @Previewable @State var buscaValor: Decimal = 0
    @Previewable @State var resultados: [Comanda] = []

    let context = DadosDeExemplo.container.mainContext
    let crud = CRUD(context: context)
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!

    let _ = {
        let voce = grupo.pessoas.first { $0.nome == "Você" }
            ?? (try! crud.criarPessoa(nome: "Você", grupo: grupo))

        guard !grupo.comandas.contains(where: { !$0.ativa }) else { return }

        // Comandas fechadas montadas direto
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

    let comandas = try! context.fetch(FetchDescriptor<Comanda>())

    VStack {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(resultados) { comanda in
                    CardComandaBusca(
                        comanda: comanda,
                        destaque: modo == .nome
                            ? .nome(buscaNome)
                            : (buscaValor > 0 ? .valor : .nenhum)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top)
        }

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
    .background(Color(.systemGroupedBackground))
    .modelContainer(DadosDeExemplo.container)
}

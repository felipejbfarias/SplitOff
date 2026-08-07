//
//  SheetPagamentoComanda.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Registra o pagamento de um participante da comanda ativa.
struct SheetPagamentoComanda: View {
    let comanda: Comanda

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var linhas: [LinhaSeletor<ParticipanteComanda>] = []
    @State private var valorTexto = ""
    @State private var valorEmCentavos = 0
    @FocusState private var valorFocado: Bool
    @State private var mensagemErro: String?
    @State private var mostrarConfirmacao = false

    // Valor digitado no teclado
    private var valor: Decimal {
        Decimal(valorEmCentavos) / 100
    }

    // Você primeiro, depois em ordem alfabética.
    private var participantesOrdenados: [ParticipanteComanda] {
        comanda.participantes.sorted {
            if $0.nomePessoa == "Você" { return true }
            if $1.nomePessoa == "Você" { return false }
            return $0.nomePessoa < $1.nomePessoa
        }
    }

    private var selecionado: ParticipanteComanda? {
        linhas.first { $0.selecionado }?.modelo
    }

    var body: some View {
        ZStack {
            NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        secao("Quem vai pagar") {
                            ListaRowsSeletor(linhas: $linhas, modo: .unica)
                        }

                        if let selecionado {
                            detalhamento(selecionado)
                        }

                        if let mensagemErro {
                            Text(mensagemErro)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                rodape
            }
            .navigationTitle("Pagar Comanda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            }

            if mostrarConfirmacao, let selecionado {
                PopUPConfirmacao(
                    titulo: "Confirmar Pagamento",
                    mensagem: "Registrar que \(selecionado.nomePessoa) pagou \(valor.formatted(.currency(code: "BRL")))?",
                    textoBotao: "Confirmar",
                    aoConfirmar: registrarPagamento,
                    aoCancelar: { mostrarConfirmacao = false }
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemGroupedBackground))
        .onAppear(perform: montarLinhas)
        .onChange(of: selecionado?.id) {
            guard selecionado != nil else { return }
            valorFocado = false
            mensagemErro = nil
            valorTexto = ""
        }
        
        // Limita o valor ao que ainda falta pagar na comanda
        .onChange(of: valorTexto) {
            let digitos = String(valorTexto.filter(\.isNumber).prefix(8))
            var centavos = Int(digitos) ?? 0
            let maximo = emCentavos(max(0, comanda.valorTotal - comanda.valorPago))
            if centavos > maximo { centavos = maximo }
            let corrigido = centavos == 0 ? digitos : String(centavos)
            if corrigido != valorTexto { valorTexto = corrigido }
            
            withAnimation(.snappy) { valorEmCentavos = centavos }
        }
        .animation(.snappy, value: valorFocado)
    }

    // Detalhamento da conta do participante escolhido + valor a pagar
    private func detalhamento(_ participante: ParticipanteComanda) -> some View {
        cartao {
            linha("Subtotal", direita: moeda(participante.subtotalContaAtual))

            if participante.taxaServicoAtual > 0 {
                Divider().padding(.leading, 16)
                linha("Taxa de serviço 10%", direita: moeda(participante.taxaServicoAtual))
            }

            if participante.couvertArtisticoAtual > 0 {
                Divider().padding(.leading, 16)
                linha("Couvert artístico", direita: moeda(participante.couvertArtisticoAtual))
            }

            Divider().padding(.leading, 16)
            linhaValorPago
        }
    }

    private var linhaValorPago: some View {
        HStack {
            Text("Valor pago")
                .fontWeight(.medium)

            Spacer()

            moeda(valor)
                .fontWeight(.medium)
                .contentTransition(.numericText())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.systemGray5), in: .capsule)
                .background {
                    TextField("", text: $valorTexto)
                        .keyboardType(.numberPad)
                        .focused($valorFocado)
                        .opacity(0)
                }
                .onTapGesture { valorFocado = true }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var rodape: some View {
        if selecionado != nil {
            BotaoSimples1(titulo: "Concluir Pagamento") {
                valorFocado = false
                mostrarConfirmacao = true
            }
            .disabled(valorEmCentavos == 0)
            .padding(.bottom, 12)
        }
    }

    private func montarLinhas() {
        linhas = participantesOrdenados.map {
            LinhaSeletor(id: $0.id, modelo: $0, nome: $0.nomePessoa, selecionado: false, valor: $0.contaAtual)
        }
    }

    // Grava o pagamento
    private func registrarPagamento() {
        guard let selecionado else { return }
        do {
            try CRUD(context: modelContext).registrarPagamento(valor, para: selecionado)
            mostrarConfirmacao = false
            dismiss()
        } catch {
            mensagemErro = error.localizedDescription
            mostrarConfirmacao = false
        }
    }

    private func emCentavos(_ valor: Decimal) -> Int {
        Int((NSDecimalNumber(decimal: valor).doubleValue * 100).rounded())
    }

    private func moeda(_ valor: Decimal) -> Text {
        Text(valor.formatted(.currency(code: "BRL")))
    }

    // Título de seção.
    private func secao<Conteudo: View>(_ titulo: String, @ViewBuilder _ conteudo: () -> Conteudo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            conteudo()
        }
    }

    // Card.
    private func cartao<Conteudo: View>(@ViewBuilder _ conteudo: () -> Conteudo) -> some View {
        VStack(spacing: 0) { conteudo() }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    // Linha rótulo à esquerda, valor cinza à direita
    private func linha(_ esquerda: String, direita: Text) -> some View {
        HStack {
            Text(esquerda).fontWeight(.medium)
            Spacer()
            direita.foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

#Preview {
    @Previewable @State var mostrar = false
    let context = DadosDeExemplo.container.mainContext
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!
    let crud = CRUD(context: context)

    let comanda: Comanda = {
        let lugar = Restaurante(nome: "Bar do Pinto", cardapio: Cardapio(nome: "Cardápio"))
        let comanda = Comanda(nome: "Conta", ativa: true, restaurante: lugar, grupo: grupo)
        context.insert(comanda)
        let pedido = Pedido(numero: 1, comanda: comanda)

        let dados: [(String, Decimal)] = [("Você", 20), ("Felipe", 30), ("Matheus", 40), ("Davi", 50)]
        for (nome, subtotal) in dados {
            let pessoa = grupo.pessoas.first { $0.nome == nome }
                ?? (try! crud.criarPessoa(nome: nome, grupo: grupo))
            let participante = ParticipanteComanda(pessoa: pessoa, comanda: comanda)
            let item = ItemPedido(nome: "Consumo \(nome)", preco: subtotal, donos: [participante])
            item.pedido = pedido
        }
        return comanda
    }()

    return Color(.systemGroupedBackground).ignoresSafeArea()
        .task { mostrar = true }
        .sheet(isPresented: $mostrar) {
            SheetPagamentoComanda(comanda: comanda)
        }
        .modelContainer(DadosDeExemplo.container)
}

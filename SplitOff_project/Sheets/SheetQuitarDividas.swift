//
//  SheetQuitarDividas.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Consulta o saldo de uma pessoa do grupo e registra uma transferência por vez.

// Ao confirmar, o backend cria a Transferencia, atualiza os saldos e o sheet fecha.
struct SheetQuitarDividas: View {
    let grupo: Grupo

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var consultado: Pessoa?
    @State private var destinatario: Pessoa?
    @State private var valorEmCentavos = 0
    @State private var valorTexto = ""
    @FocusState private var valorFocado: Bool
    @State private var mostrarConfirmacao = false
    @State private var mensagemErro: String?

    // Valor digitado no teclado, em reais.
    private var valor: Decimal {
        Decimal(valorEmCentavos) / 100
    }

    private var pessoasDoGrupo: [Pessoa] {
        grupo.pessoas.sorted {
            if $0.nome == "Você" { return true }
            if $1.nome == "Você" { return false }
            return $0.nome < $1.nome
        }
    }

    // Enquanto o algoritmo não existir, as listas ficam ocultas. VAMBORA DAVIZAOO!!
    private var sugestoes: [SugestaoTransferencia] {
        PlanejadorQuitacaoDividas.calcularSugestoes(para: grupo)
    }

    private var sugestoesAPagar: [SugestaoTransferencia] {
        sugestoes.filter { $0.devedor == consultado }
    }

    private var sugestoesAReceber: [SugestaoTransferencia] {
        sugestoes.filter { $0.credor == consultado }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            cartaoConsulta

                            if let consultado {
                                secaoRegistrarTransferencia(consultado)
                            }

                            if destinatario != nil {
                                valorDigitado
                            }

                            if let mensagemErro {
                                Text(mensagemErro)
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    rodape
                }
                .navigationTitle("Quitar Dívidas")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }

            if mostrarConfirmacao, let consultado, let destinatario {
                PopUPConfirmacao(
                    titulo: "Confirmar Pagamento",
                    mensagem: "Registrar que \(consultado.nome) pagou \(textoMoeda(valor)) a \(destinatario.nome)?",
                    textoBotao: "Confirmar",
                    aoConfirmar: registrarTransferencia,
                    aoCancelar: { mostrarConfirmacao = false }
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemGroupedBackground))
        .onChange(of: consultado) {
            withAnimation(.snappy) {
                destinatario = nil
                valorTexto = ""
                mensagemErro = nil
            }
            valorFocado = false
        }
        .onChange(of: destinatario) {
            guard destinatario != nil else { return }
            withAnimation(.snappy) {
                valorTexto = ""
                mensagemErro = nil
            }
            Task { valorFocado = true }
        }
        .onChange(of: valorTexto) {
            let digitos = String(valorTexto.filter(\.isNumber).prefix(8))
            if digitos != valorTexto { valorTexto = digitos }
            withAnimation(.snappy) { valorEmCentavos = Int(digitos) ?? 0 }
        }
        .animation(.snappy, value: valorFocado)
    }

    // Card da consulta
    private var cartaoConsulta: some View {
        VStack(spacing: 20) {
            ListaRowsPicker(linhas: [
                .picker(
                    titulo: "Consultar",
                    opcoes: pessoasDoGrupo.map(\.nome),
                    selecao: bindingNome($consultado, opcoes: pessoasDoGrupo)
                )
            ])

            // Durante a digitação o card recolhe.
            if let consultado, !valorFocado {
                cartao { saldoDetalhado(consultado) }
            }
        }
    }

    // Saldo da pessoa consultada com as listas de sugestões de transferências
    private func saldoDetalhado(_ pessoa: Pessoa) -> some View {
        VStack(spacing: 28) {
            resumoSaldo(pessoa)

            if !sugestoesAPagar.isEmpty {
                listaSugestoes("A Pagar", sugestoesAPagar) { $0.credor.nome }
            }

            if !sugestoesAReceber.isEmpty {
                listaSugestoes("A Receber", sugestoesAReceber) { $0.devedor.nome }
            }
        }
        .padding(.top, 24)
        .padding(.bottom, sugestoesAPagar.isEmpty && sugestoesAReceber.isEmpty ? 32 : 8)
        .frame(maxWidth: .infinity)
    }

    // Total a pagar ou a receber, conforme o sinal do saldo, zerado fica cinza.
    private func resumoSaldo(_ pessoa: Pessoa) -> some View {
        VStack(spacing: 8) {
            Text(pessoa.saldo > 0 ? "Total a Receber" : "Total a Pagar")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(textoMoeda(abs(pessoa.saldo)))
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(pessoa.saldo == 0 ? Color.secondary : pessoa.saldo < 0 ? .red : .green)
        }
    }

    private func listaSugestoes(
        _ titulo: String,
        _ sugestoes: [SugestaoTransferencia],
        nome: @escaping (SugestaoTransferencia) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)

            linhas(sugestoes) { sugestao in
                linha(nome(sugestao), direita: moeda(sugestao.valor))
            }
        }
    }

    private func secaoRegistrarTransferencia(_ consultado: Pessoa) -> some View {
        let opcoes = pessoasDoGrupo.filter { $0 != consultado }
        return ListaRowsPicker(
            titulo: "Registrar Transferência",
            linhas: [
                .picker(
                    titulo: "Para quem",
                    opcoes: opcoes.map(\.nome),
                    selecao: bindingNome($destinatario, opcoes: opcoes)
                )
            ]
        )
    }

    // Digitar transferencia
    private var valorDigitado: some View {
        VStack(spacing: 8) {
            Text("Valor Pago")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(textoMoeda(valor))
                .font(.system(size: 40, weight: .bold))
                .contentTransition(.numericText())
        }
        .padding(.top, 24)
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .background {
            TextField("", text: $valorTexto)
                .keyboardType(.numberPad)
                .focused($valorFocado)
                .opacity(0)
        }
        .onTapGesture { valorFocado = true }
    }

    // "Continuar" fecha o teclado depois entra o botão de confirmar.
    @ViewBuilder
    private var rodape: some View {
        if valorFocado {
            BotaoSimples1(titulo: "Continuar") {
                valorFocado = false
            }
            .disabled(valorEmCentavos == 0)
            .padding(.bottom, 12)
        } else if destinatario != nil {
            BotaoSimples1(titulo: "Confirmar Transferência") {
                mostrarConfirmacao = true
            }
            .disabled(valorEmCentavos == 0)
            .padding(.bottom, 12)
        }
    }

    // Registra no backend
    private func registrarTransferencia() {
        guard let consultado, let destinatario else { return }

        do {
            try CRUD(context: modelContext).registrarTransferencia(
                valor: valor,
                de: consultado,
                para: destinatario,
                tipo: .quitacao
            )
            dismiss()
        } catch {
            mensagemErro = error.localizedDescription
            mostrarConfirmacao = false
        }
    }

    private func bindingNome(_ selecao: Binding<Pessoa?>, opcoes: [Pessoa]) -> Binding<String?> {
        Binding(
            get: { selecao.wrappedValue?.nome },
            set: { nome in selecao.wrappedValue = opcoes.first { $0.nome == nome } }
        )
    }

    private func textoMoeda(_ valor: Decimal) -> String {
        valor.formatted(.currency(code: "BRL"))
    }

    private func moeda(_ valor: Decimal) -> Text {
        Text(textoMoeda(valor)).fontWeight(.medium)
    }

    // Card
    private func cartao<Conteudo: View>(@ViewBuilder _ conteudo: () -> Conteudo) -> some View {
        VStack(spacing: 0) { conteudo() }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    // Linhas com divisores
    @ViewBuilder
    private func linhas<Item: Identifiable, Conteudo: View>(
        _ itens: [Item],
        @ViewBuilder _ linha: @escaping (Item) -> Conteudo
    ) -> some View {
        ForEach(itens) { item in
            linha(item)
            if item.id != itens.last?.id {
                Divider().padding(.leading, 16)
            }
        }
    }

    // Linha padrão.
    private func linha(_ esquerda: String, direita: Text) -> some View {
        HStack {
            Text(esquerda).fontWeight(.medium)
            Spacer()
            direita
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

#Preview("1 devedor, 1 credor") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "Quitacao simples",
        saldos: [
            ("Você", 0),
            ("Ana", -42),
            ("Bruno", 42)
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

#Preview("1 devedor, varios credores") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "Uma pessoa deve para varias",
        saldos: [
            ("Você", -100),
            ("Ana", 70),
            ("Bruno", 20),
            ("Carla", 10),
            ("Diego", 0)
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

#Preview("Cadeia compensada") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "X deve Y, Y deve W",
        saldos: [
            // X deve 40 para Y, Y deve 40 para W: Y zera, X deve direto para W
            ("Você", 0),
            ("X", -40),
            ("Y", 0),
            ("W", 40)
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

#Preview("Cadeia: intermediario recebe") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "X deve mais do que Y repassa",
        saldos: [
            // X deve 70 para Y, Y deve 50 para W: W recebe 50 e Y ainda recebe 20.
            ("Você", 0),
            ("X", -70),
            ("Y", 20),
            ("W", 50)
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

#Preview("Cadeia: intermediario paga") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "X deve menos do que Y repassa",
        saldos: [
            // X deve 50 para Y, Y deve 70 para W: X paga 50 e Y ainda paga 20.
            ("Você", 0),
            ("X", -50),
            ("Y", -20),
            ("W", 70)
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

#Preview("Cadeia com centavos") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "Compensacao decimal em cadeia",
        saldos: [
            // X deve 33,35 para Y, Y deve 33,35 para W: Y zera com centavos.
            ("Você", 0),
            ("X", PreviewQuitarDividas.decimal("-33.35")),
            ("Y", 0),
            ("W", PreviewQuitarDividas.decimal("33.35"))
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

#Preview("Cadeia longa compensada") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "X passa por Y e W ate Z",
        saldos: [
            // X deve para Y, Y deve para W, W deve para Z: só X e Z ficam com saldo.
            ("Você", 0),
            ("X", -60),
            ("Y", 0),
            ("W", 0),
            ("Z", 60)
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

#Preview("Varios devedores, 1 credor") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "Varias pessoas devem para uma",
        saldos: [
            ("Você", 160),
            ("Ana", -80),
            ("Bruno", -45),
            ("Carla", -25),
            ("Diego", -10)
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

#Preview("Complexo balanceado") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "Muitos saldos cruzados",
        saldos: [
            ("Você", -70),
            ("Ana", -50),
            ("Bruno", -20),
            ("Carla", 90),
            ("Diego", 30),
            ("Elisa", 20),
            ("Fabi", 0)
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

#Preview("Valores decimais") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "Centavos preservados",
        saldos: [
            ("Você", PreviewQuitarDividas.decimal("10.25")),
            ("Ana", PreviewQuitarDividas.decimal("-4.10")),
            ("Bruno", PreviewQuitarDividas.decimal("-6.15")),
            ("Carla", 0)
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

#Preview("Sem sugestoes") {
    @Previewable @State var mostrar = false
    let cenario = PreviewQuitarDividas.cenario(
        nome: "Tudo zerado",
        saldos: [
            ("Você", 0),
            ("Ana", 0),
            ("Bruno", 0),
            ("Carla", 0)
        ]
    )

    PreviewQuitarDividas.sheet(mostrar: $mostrar, cenario: cenario)
}

@MainActor
private enum PreviewQuitarDividas {
    struct Cenario {
        let container: ModelContainer
        let grupo: Grupo
    }

    static func cenario(nome: String, saldos: [(String, Decimal)]) -> Cenario {
        let schema = Schema(splitOffModels)
        let configuracao = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuracao])
        let context = container.mainContext
        let grupo = Grupo(nome: nome)

        context.insert(grupo)
        grupo.pessoas = saldos.map { nome, saldo in
            let pessoa = Pessoa(nome: nome, saldo: saldo, grupo: grupo)
            context.insert(pessoa)
            return pessoa
        }

        return Cenario(container: container, grupo: grupo)
    }

    static func decimal(_ valor: String) -> Decimal {
        Decimal(string: valor, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    static func sheet(mostrar: Binding<Bool>, cenario: Cenario) -> some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
            .task { mostrar.wrappedValue = true }
            .sheet(isPresented: mostrar) {
                SheetQuitarDividas(grupo: cenario.grupo)
            }
            .modelContainer(cenario.container)
    }
}

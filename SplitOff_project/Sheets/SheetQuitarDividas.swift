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
        cartao {
            rowPicker(titulo: "Consultar", selecao: $consultado, opcoes: pessoasDoGrupo)

            // Durante a digitação o card recolh
            if let consultado, !valorFocado {
                saldoDetalhado(consultado)
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
        secao("Registrar Transferência") {
            cartao {
                rowPicker(
                    titulo: "Para quem",
                    selecao: $destinatario,
                    opcoes: pessoasDoGrupo.filter { $0 != consultado }
                )
            }
        }
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

    private func rowPicker(titulo: String, selecao: Binding<Pessoa?>, opcoes: [Pessoa]) -> some View {
        HStack {
            Text(titulo)
                .fontWeight(.medium)
            Spacer()
            PickerSeletor(
                titulo: "Selecionar",
                opcoes: opcoes.map(\.nome),
                selecao: Binding(
                    get: { selecao.wrappedValue?.nome },
                    set: { nome in selecao.wrappedValue = opcoes.first { $0.nome == nome } }
                ),
                acaoAdicionar: {},
                tem: false
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func textoMoeda(_ valor: Decimal) -> String {
        valor.formatted(.currency(code: "BRL"))
    }

    private func moeda(_ valor: Decimal) -> Text {
        Text(textoMoeda(valor)).fontWeight(.medium)
    }

    // Título.
    private func secao<Conteudo: View>(_ titulo: String, @ViewBuilder _ conteudo: () -> Conteudo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            conteudo()
        }
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

#Preview {
    @Previewable @State var mostrar = false
    let context = DadosDeExemplo.container.mainContext
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!

    // Ana deve, Bruno emprestou e "Você" está presente como em todos os grupos.
    let _ = {
        if !grupo.pessoas.contains(where: { $0.nome == "Você" }) {
            _ = try? CRUD(context: context).criarPessoa(nome: "Você", grupo: grupo)
        }
        for pessoa in grupo.pessoas {
            switch pessoa.nome {
                case "Ana": pessoa.saldo = -27
                case "Bruno": pessoa.saldo = 27
                default: pessoa.saldo = 0
            }
        }
    }()

    Color(.systemGroupedBackground).ignoresSafeArea()
        .task { mostrar = true }
        .sheet(isPresented: $mostrar) {
            SheetQuitarDividas(grupo: grupo)
        }
        .modelContainer(DadosDeExemplo.container)
}

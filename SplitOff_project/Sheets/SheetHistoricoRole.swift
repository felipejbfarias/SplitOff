//
//  SheetHistoricoRole.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Sheet de histórico da comanda
struct SheetHistoricoRole: View {
    let comanda: Comanda

    @Environment(\.dismiss) private var dismiss
    @State private var aba: Aba

    enum Aba: String, CaseIterable {
        case comanda = "Comanda"
        case pagamentos = "Pagamentos"
    }

    init(comanda: Comanda, abaInicial: Aba = .comanda) {
        self.comanda = comanda
        self._aba = State(initialValue: abaInicial)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Picker("", selection: $aba) {
                    ForEach(Aba.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch aba {
                    case .comanda: abaComanda
                    case .pagamentos: abaPagamentos
                }
            }
            .navigationTitle(comanda.restaurante?.nome ?? comanda.nome)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemGroupedBackground))
    }

    // Aba Comanda
    private var abaComanda: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 32)

                    VStack(spacing: 8) {
                        Text("Total da Comanda")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(comanda.valorTotal.formatted(.currency(code: "BRL")))
                            .font(.system(size: 40, weight: .bold))
                    }

                    Spacer(minLength: 56)

                    secao("Por Pessoa") {
                        cartao {
                            linhas(comanda.participantes) { participante in
                                linha(participante.nomePessoa, direita: moeda(participante.contaAtual))
                            }
                        }
                    }

                    Color.clear
                        .frame(height: 28)

                    cartao {
                        linha("Subtotal", direita: moeda(comanda.subtotal))
                        Divider().padding(.leading, 16)
                        linha("Taxa de serviço 10%", direita: moeda(comanda.taxaServico))
                    }
                }
                .frame(minHeight: geometry.size.height, alignment: .bottom)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }

    // Aba pagamentos
    private var abaPagamentos: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 32)

                    if todosQuitaram {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 84))
                                .foregroundStyle(.green)
                            Text("Tudo Certo")
                                .font(.title.bold())
                                .foregroundStyle(.green)
                            Text("Todos Quitaram")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        VStack(spacing: 8) {
                            Text("Faltou Acertar")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(faltouAcertar.formatted(.currency(code: "BRL")))
                                .font(.system(size: 40, weight: .bold))
                        }
                    }

                    Spacer(minLength: 56)

                    cartao {
                        linhas(comanda.participantes) { participante in
                            linha(participante.nomePessoa, direita: textoStatus(participante))
                        }
                    }
                }
                .frame(minHeight: geometry.size.height, alignment: .bottom)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    // Total pendente entre participantes.
    private var faltouAcertar: Decimal {
        comanda.participantes.reduce(0) { total, participante in
            let falta = participante.contaAtual - participante.valorPago
            return total + (falta > 0 ? falta : 0)
        }
    }

    private var todosQuitaram: Bool {
        faltouAcertar <= Comanda.limiarFechamento
    }

    // Texto exibido no status de pagamento.
    private func textoStatus(_ participante: ParticipanteComanda) -> Text {
        let diferenca = participante.valorPago - participante.contaAtual
        if abs(diferenca) <= Comanda.limiarFechamento {
            return Text("Quitado").foregroundStyle(.secondary)
        } else if diferenca < 0 {
            return Text("- \(abs(diferenca).formatted(.currency(code: "BRL")))").foregroundStyle(.red)
        } else {
            return Text("+ \(diferenca.formatted(.currency(code: "BRL")))").foregroundStyle(.green)
        }
    }

    // Valor formatado em reais.
    private func moeda(_ valor: Decimal) -> Text {
        Text(valor.formatted(.currency(code: "BRL"))).fontWeight(.medium)
    }

    // Seção com título.
    private func secao<Conteudo: View>(_ titulo: String, @ViewBuilder _ conteudo: () -> Conteudo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titulo)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            conteudo()
        }
    }

    // Card padrão.
    private func cartao<Conteudo: View>(@ViewBuilder _ conteudo: () -> Conteudo) -> some View {
        VStack(spacing: 0) { conteudo() }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    // Linhas com divisores.
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

#Preview("Com dívidas") {
    @Previewable @State var mostrar = false
    let context = DadosDeExemplo.container.mainContext
    let comanda = try! context.fetch(FetchDescriptor<Comanda>()).first!

    // Estados variados de pagamento.
    let _ = {
        for (i, p) in comanda.participantes.enumerated() {
            switch i % 3 {
                case 0: p.valorPago = p.contaAtual
                case 1: p.valorPago = p.contaAtual / 2
                default: p.valorPago = p.contaAtual * 2
            }
        }
    }()

    Color(.systemGroupedBackground).ignoresSafeArea()
        .task { mostrar = true }
        .sheet(isPresented: $mostrar) {
            SheetHistoricoRole(comanda: comanda, abaInicial: .pagamentos)
        }
        .modelContainer(DadosDeExemplo.container)
}

#Preview("Todos quitaram") {
    @Previewable @State var mostrar = false
    let context = DadosDeExemplo.container.mainContext
    let comanda = try! context.fetch(FetchDescriptor<Comanda>()).first!

    let _ = {
        for p in comanda.participantes { p.valorPago = p.contaAtual }
    }()

    Color(.systemGroupedBackground).ignoresSafeArea()
        .task { mostrar = true }
        .sheet(isPresented: $mostrar) {
            SheetHistoricoRole(comanda: comanda, abaInicial: .pagamentos)
        }
        .modelContainer(DadosDeExemplo.container)
}

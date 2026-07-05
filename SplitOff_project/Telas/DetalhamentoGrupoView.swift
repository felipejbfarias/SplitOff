//
//  DetalhamentoGrupoView.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

struct DetalhamentoGrupoView: View {
    @Environment(\.modelContext) private var context

    @Bindable var grupo: Grupo

    private enum Aba: String, CaseIterable {
        case historico = "Histórico"
        case membros = "Membros"
    }

    @State private var aba: Aba = .historico
    @State private var mostrarEditarGrupo = false
    @State private var mostrarQuitarDividas = false
    @State private var comandaParaApagar: Comanda?
    @State private var comandaHistoricoSelecionada: Comanda?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopBar(
                    mostrarVoltar: true,
                    simboloDireita: "person.fill.badge.plus"
                ) {
                    mostrarEditarGrupo = true
                }

                Text(grupo.nome)
                    .font(.system(size: 34, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Picker("Aba", selection: $aba) {
                    ForEach(Aba.allCases, id: \.self) { aba in
                        Text(aba.rawValue).tag(aba)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 12)

                ScrollView {
                    switch aba {
                    case .historico:
                        abaHistorico
                    case .membros:
                        abaMembros
                    }
                }

                if aba == .membros {
                    BotaoSimples1(titulo: "Quitar") {
                        mostrarQuitarDividas = true
                    }
                    .padding(.bottom, 12)
                }
            }

            if let comandaParaApagar {
                PopUPDestrutivo.apagarComanda(comandaParaApagar) {
                    removerComanda(comandaParaApagar)
                } aoCancelar: {
                    self.comandaParaApagar = nil
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $mostrarEditarGrupo) {
            SheetEditarGrupo(grupo: grupo)
        }
        .sheet(isPresented: $mostrarQuitarDividas) {
            SheetQuitarDividas(grupo: grupo)
        }
        .sheet(item: $comandaHistoricoSelecionada) { comanda in
            SheetHistoricoRole(comanda: comanda)
        }
    }

    private var abaHistorico: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Maiores dívidas")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            CardMaioresDividas(pessoas: maioresDividas)

            Text("Histórico de comandas")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            ForEach(comandasOrdenadas) { comanda in
                RowGrupoHistorico(comanda: comanda) {
                    comandaHistoricoSelecionada = comanda
                } aoRemover: {
                    comandaParaApagar = comanda
                }
            }
        }
        .padding()
    }

    private var abaMembros: some View {
        LazyVStack(spacing: 0) {
            ForEach(pessoasOrdenadas) { pessoa in
                HStack {
                    Text(pessoa.nome)
                        .font(.body)

                    Spacer()

                    Text(textoSaldo(pessoa))
                        .font(.subheadline)
                        .foregroundStyle(corSaldo(pessoa))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if pessoa.id != pessoasOrdenadas.last?.id {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
        .padding()
    }

    private var comandasOrdenadas: [Comanda] {
        grupo.comandas.sorted { $0.data > $1.data }
    }

    private var pessoasOrdenadas: [Pessoa] {
        grupo.pessoas.sorted {
            if $0.nome == CRUD.nomeVoce { return true }
            if $1.nome == CRUD.nomeVoce { return false }
            return $0.nome < $1.nome
        }
    }

    private var maioresDividas: [Pessoa] {
        grupo.pessoas
            .filter { $0.saldo < 0 }
            .sorted { $0.saldo < $1.saldo }
            .prefix(3)
            .map { $0 }
    }

    private func textoSaldo(_ pessoa: Pessoa) -> String {
        if pessoa.saldo < 0 {
            return "Deve \(abs(pessoa.saldo).formatted(.currency(code: "BRL")))"
        } else if pessoa.saldo > 0 {
            return "Emprestou \(pessoa.saldo.formatted(.currency(code: "BRL")))"
        } else {
            return "Quitado"
        }
    }

    private func corSaldo(_ pessoa: Pessoa) -> Color {
        if pessoa.saldo < 0 {
            return .red
        } else if pessoa.saldo > 0 {
            return .green
        } else {
            return .secondary
        }
    }

    private func removerComanda(_ comanda: Comanda) {
        let crud = CRUD(context: context)

        do {
            try crud.removerComanda(comanda)
            comandaParaApagar = nil
        } catch {
            print("Erro ao remover comanda: \(error)")
        }
    }
}

private struct CardMaioresDividas: View {
    let pessoas: [Pessoa]

    var body: some View {
        HStack {
            if pessoas.isEmpty {
                Text("Nenhuma dívida no momento")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(pessoas) { pessoa in
                    VStack(spacing: 6) {
                        Image("maca_cortada")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)

                        Text(pessoa.nome)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        Text(abs(pessoa.saldo).formatted(.currency(code: "BRL")))
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!

    NavigationStack {
        DetalhamentoGrupoView(grupo: grupo)
    }
    .modelContainer(DadosDeExemplo.container)
}

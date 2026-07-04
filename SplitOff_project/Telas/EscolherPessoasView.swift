//
//  EscolherPessoasView.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Etapa 1 do novo pedido: escolher quem da comanda ativa está fazendo o pedido.
struct EscolherPessoasView: View {
    let comanda: Comanda

    var aoConcluir: (() -> Void)? = nil

    @State private var linhas: [LinhaSeletor<ParticipanteComanda>] = []
    @State private var irParaCardapio = false

    private var autor: ParticipanteComanda? {
        linhas.first(where: \.selecionado)?.modelo
    }

    var body: some View {
        VStack(spacing: 0) {
            TopBar()

            Text("Novo Pedido")
                .font(.system(size: 34, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 8)

            BarraProgresso(etapa: .escolherPessoas)
                .padding(.horizontal)
                .padding(.top, 28)

            ScrollView {
                VStack(spacing: 20) {
                    Text("Quem está Fazendo o Pedido?")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.tertiary)

                    ListaRowsSeletor(linhas: $linhas, modo: .unica)
                }
                .padding()
                .padding(.top, 12)
            }

            BotaoSimples1(titulo: "Confirmar") { irParaCardapio = true }
                .disabled(autor == nil)
                .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: montarLinhas)
        .navigationDestination(isPresented: $irParaCardapio) {
            if let autor {
                CardapioView(comanda: comanda, autor: autor, aoConcluir: aoConcluir)
            }
        }
    }

    // Participantes da comanda com Você primeiro e já selecionado
    private func montarLinhas() {
        guard linhas.isEmpty else { return }

        let participantes = comanda.participantes.sorted {
            if $0.nomePessoa == "Você" { return true }
            if $1.nomePessoa == "Você" { return false }
            return $0.nomePessoa < $1.nomePessoa
        }

        linhas = participantes.enumerated().map { indice, participante in
            LinhaSeletor(
                id: participante.id,
                modelo: participante,
                nome: participante.nomePessoa,
                selecionado: indice == 0
            )
        }
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let crud = CRUD(context: context)
    let comanda = try! context.fetch(FetchDescriptor<Comanda>()).first { $0.ativa }!

    // Participantes do mock, com Você presente como em todos os grupos.
    let _ = {
        for nome in ["Você", "Matheus", "Felipe", "Davi"] where !comanda.participantes.contains(where: { $0.nomePessoa == nome }) {
            guard let grupo = comanda.grupo else { return }
            let pessoa = grupo.pessoas.first { $0.nome == nome } ?? (try! crud.criarPessoa(nome: nome, grupo: grupo))
            _ = try? crud.adicionarParticipante(pessoa, a: comanda)
        }
    }()

    NavigationStack {
        EscolherPessoasView(comanda: comanda)
    }
    .modelContainer(DadosDeExemplo.container)
}

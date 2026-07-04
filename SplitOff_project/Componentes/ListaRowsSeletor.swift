//
//  ListaRowsSeletor.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Como a lista trata a seleção das linhas.
enum ModoSelecao {
    case unica      // escolhe uma e limpa as outras
    case multipla   // toggle livre em várias
}

// Uma linha da lista: guarda o próprio modelo, então a tela recupera o objeto selecionado direto, sem confundir os ids das duas entidades.
struct LinhaSeletor<Modelo>: Identifiable {
    let id: UUID
    let modelo: Modelo
    let nome: String
    var selecionado: Bool
    var valor: Decimal? = nil
}

// Lista de pessoas com seletor. Serve para escolher a pessoa base do pedido, marcar quem entra na comanda/divisão, ou escolher quem paga (com valor).
struct ListaRowsSeletor<Modelo>: View {
    @Binding var linhas: [LinhaSeletor<Modelo>]
    var modo: ModoSelecao = .multipla

    // Nomes que sempre participam e não podem ser desmarcados
    var fixas: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            ForEach(fixas, id: \.self) { nome in
                linhaFixa(nome)
                if nome != fixas.last || !linhas.isEmpty {
                    Divider().padding(.leading, 52)
                }
            }

            ForEach($linhas) { $linha in
                LinhaSeletorView(
                    nome: linha.nome,
                    valor: linha.valor,
                    selecionado: linha.selecionado
                ) { alternar(linha.id) }
                if linha.id != linhas.last?.id {
                    Divider().padding(.leading, 52)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    // Linha travada, check preenchido e nome em cinza, sem interação.
    private func linhaFixa(_ nome: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(nome)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // Aplica a seleção conforme o modo.
    private func alternar(_ id: UUID) {
        guard let i = linhas.firstIndex(where: { $0.id == id }) else { return }
        switch modo {
            case .unica:
                for j in linhas.indices { linhas[j].selecionado = (j == i) }
            case .multipla:
                linhas[i].selecionado.toggle()
        }
    }
}

private struct LinhaSeletorView: View {
    let nome: String
    let valor: Decimal?
    let selecionado: Bool
    let aoTocar: () -> Void

    var body: some View {
        Button(action: aoTocar) {
            HStack(spacing: 12) {
                Image(systemName: selecionado ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selecionado ? Color.accentColor : Color.secondary)

                Text(nome)
                    .foregroundStyle(.primary)

                Spacer()

                // Valor à direita, só no uso de pagamento.
                if let valor {
                    Text(valor.formatted(.currency(code: "BRL")))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var pessoaBase: [LinhaSeletor<Pessoa>] = []
    @Previewable @State var grupo: [LinhaSeletor<Pessoa>] = []
    @Previewable @State var pagamento: [LinhaSeletor<ParticipanteComanda>] = []
    let context = DadosDeExemplo.container.mainContext
    let pessoas = (try? context.fetch(FetchDescriptor<Pessoa>())) ?? []
    let participantes = (try? context.fetch(FetchDescriptor<Comanda>()))?.first?.participantes ?? []

    ScrollView {
        VStack(spacing: 24) {
            // Seleção única de Pessoa (pessoa base do pedido).
            ListaRowsSeletor(linhas: $pessoaBase, modo: .unica)

            // Seleção múltipla de Pessoa (quem do grupo entra), começa tudo marcado.
            ListaRowsSeletor(linhas: $grupo, modo: .multipla)

            // Seleção única de ParticipanteComanda com valor (pagamento).
            ListaRowsSeletor(linhas: $pagamento, modo: .unica)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .onAppear {
        // Cada lista guarda o modelo real, tipado, do backend.
        pessoaBase = pessoas.map { LinhaSeletor(id: $0.id, modelo: $0, nome: $0.nome, selecionado: false) }
        grupo = pessoas.map { LinhaSeletor(id: $0.id, modelo: $0, nome: $0.nome, selecionado: true) }
        pagamento = participantes.map {
            LinhaSeletor(id: $0.id, modelo: $0, nome: $0.nomePessoa, selecionado: false, valor: $0.contaAtual)
        }
    }
}

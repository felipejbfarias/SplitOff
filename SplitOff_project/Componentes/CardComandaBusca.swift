//
//  CardComandaBusca.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 02/06/26.
//

import SwiftUI
import SwiftData

// O que o card destaca em accent conforme a busca ativa.
enum DestaqueBusca {
    case nenhum
    case nome(String) // trecho digitado na busca por lugar
    case valor
}

// Card isolado de resultado da busca
struct CardComandaBusca: View {
    let comanda: Comanda
    var destaque: DestaqueBusca = .nenhum

    private var nomeLugar: String {
        comanda.restaurante?.nome ?? comanda.nome
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.headline)
                if let grupo = comanda.grupo?.nome {
                    Text(grupo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let gasto = comanda.gastoDoVoce {
                Text(gasto.formatted(.currency(code: "BRL")))
                    .fontWeight(.medium)
                    .foregroundStyle(destacaValor ? Color.accentColor : .primary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    private var destacaValor: Bool {
        if case .valor = destaque { return true }
        return false
    }

    // Título com o trecho buscado pintado em pink
    private var titulo: AttributedString {
        var texto = AttributedString(nomeLugar)

        if case let .nome(busca) = destaque {
            let buscaLimpa = busca.trimmingCharacters(in: .whitespaces)
            if !buscaLimpa.isEmpty,
               let intervalo = nomeLugar.range(of: buscaLimpa, options: [.caseInsensitive, .diacriticInsensitive]),
               let intervaloAtributado = Range(intervalo, in: texto) {
                texto[intervaloAtributado].foregroundColor = .accentColor
            }
        }

        return texto
    }
}

// Conta consumida por você na comanda
extension Comanda {
    var gastoDoVoce: Decimal? {
        participantes.first { $0.nomePessoa == "Você" }?.contaAtual
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let crud = CRUD(context: context)
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!
    let comanda = try! context.fetch(FetchDescriptor<Comanda>()).first!

    let _ = {
        guard !grupo.pessoas.contains(where: { $0.nome == "Você" }) else { return }
        let voce = try! crud.criarPessoa(nome: "Você", grupo: grupo)
        let participante = try! crud.adicionarParticipante(voce, a: comanda)
        _ = try! crud.criarItemPedido(nome: "Suco", preco: 12, pedido: comanda.pedidos.first!, donos: [participante])
    }()

    VStack(spacing: 12) {
        CardComandaBusca(comanda: comanda)
        CardComandaBusca(comanda: comanda, destaque: .nome("Cant"))
        CardComandaBusca(comanda: comanda, destaque: .valor)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .modelContainer(DadosDeExemplo.container)
}

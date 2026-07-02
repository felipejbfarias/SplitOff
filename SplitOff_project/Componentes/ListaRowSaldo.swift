//
//  ListaRowSaldo.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Lista das pessoas do grupo com o saldo geral de cada um
struct ListaRowSaldo: View {
    let pessoas: [Pessoa]

    private let alturaRow: CGFloat = 60

    // Ordem: Você primeiro, depois Devedores, Credores e Quitados.
    private var pessoasOrdenadas: [Pessoa] {
        pessoas.sorted { a, b in
            let ra = ordem(a), rb = ordem(b)
            return ra == rb ? a.nome < b.nome : ra < rb
        }
    }

    private func ordem(_ pessoa: Pessoa) -> Int {
        if pessoa.nome == "Você" { return 0 }
        if pessoa.saldo < 0 { return 1 }   // Devedor
        if pessoa.saldo > 0 { return 2 }   // Credor
        return 3                           // Quitado
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(pessoasOrdenadas) { pessoa in
                row(pessoa)
                if pessoa.id != pessoasOrdenadas.last?.id {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    // nome à esquerda, situação do saldo à direita.
    private func row(_ pessoa: Pessoa) -> some View {
        HStack {
            Text(pessoa.nome)
                .font(.system(size: 17, weight: .regular))

            Spacer()

            Text(textoSaldo(pessoa.saldo))
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(corSaldo(pessoa.saldo))
        }
        .padding(.horizontal, 16)
        .frame(minHeight: alturaRow)
    }

    // Texto da situação conforme o sinal do saldo.
    private func textoSaldo(_ saldo: Decimal) -> String {
        if saldo < 0 {
            return "Deve \(moeda(abs(saldo)))"
        } else if saldo > 0 {
            return "Emprestou \(moeda(saldo))"
        } else {
            return "Quitado"
        }
    }

    private func corSaldo(_ saldo: Decimal) -> Color {
        if saldo < 0 { return .red }
        if saldo > 0 { return .green }
        return .secondary
    }

    private func moeda(_ valor: Decimal) -> String {
        valor.formatted(.currency(code: "BRL"))
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let grupo = try! context.fetch(FetchDescriptor<Grupo>()).first!

    let _ = {
        let crud = CRUD(context: context)
        for nome in ["Você", "Diego"] where !grupo.pessoas.contains(where: { $0.nome == nome }) {
            _ = try? crud.criarPessoa(nome: nome, grupo: grupo)
        }
        let saldos: [String: Decimal] = [
            "Você": -140,   // Deve 140
            "Bruno": -50,   // Deve 50
            "Carla": -50,   // Deve 50
            "Ana": 240,     // Emprestou 240
            "Diego": 0      // Quitado
        ]
        for pessoa in grupo.pessoas {
            pessoa.saldo = saldos[pessoa.nome] ?? 0
        }
    }()

    ScrollView {
        ListaRowSaldo(pessoas: grupo.pessoas)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
    .modelContainer(DadosDeExemplo.container)
}

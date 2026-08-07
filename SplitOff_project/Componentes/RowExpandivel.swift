//
//  RowExpandivel.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Uma linha do detalhe expandido: texto à esquerda, valor à direita.
struct DetalheExpandivel: Identifiable {
    let id = UUID()
    let texto: String
    let valor: Decimal
}

// Card expansível com detalhes ao abrir. Usado para ver um pedido ou a conta de uma pessoa
struct RowExpandivel: View {
    let titulo: String
    let subtitulo: String
    let valor: Decimal
    var valorPrefixo: String = ""
    var valorCor: Color = .secondary
    let detalhes: [DetalheExpandivel]

    @State private var expandido = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy) { expandido.toggle() }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(titulo)
                            .font(.headline)
                        Text(subtitulo)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(valorPrefixo + valor.formatted(.currency(code: "BRL")))
                        .foregroundStyle(valorCor)
                    Image(systemName: expandido ? "chevron.down" : "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if expandido {
                Divider().padding(.horizontal, 16)
                ForEach(detalhes) { detalhe in
                    HStack(spacing: 12) {
                        Text(detalhe.texto)
                        Spacer()
                        Text(detalhe.valor.formatted(.currency(code: "BRL")))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}

extension RowExpandivel {
    // Detalhamento de um pedido: cada item com quantidade cheia e preço cheio.
    init(pedido: Pedido) {
        self.init(
            titulo: "Pedido \(pedido.numero)",
            subtitulo: pedido.responsaveis,
            valor: pedido.valorTotal,
            detalhes: pedido.itens.map {
                DetalheExpandivel(texto: "\(Self.quantidade(de: $0)) \($0.nome)", valor: $0.preco)
            }
        )
    }

    // Conta de uma pessoa durante a comanda: itens, valor por dono e extras.
    init(conta participante: ParticipanteComanda) {
        self.init(
            titulo: participante.nomePessoa,
            subtitulo: "Não pago",
            valor: participante.contaAtual,
            detalhes: Self.detalhesConta(participante)
        )
    }

    // Conta após o pagamento: mostra o valor pago e o saldo daquela comanda.
    init(contaPaga participante: ParticipanteComanda) {
        let diferenca = participante.valorPago - participante.contaAtual

        let subtitulo: String
        let cor: Color
        if abs(diferenca) <= Comanda.limiarFechamento {
            subtitulo = "Quitado"
            cor = .secondary
        } else if diferenca < 0 {
            subtitulo = "Deve \(abs(diferenca).formatted(.currency(code: "BRL")))"
            cor = .red
        } else {
            subtitulo = "Emprestou \(diferenca.formatted(.currency(code: "BRL")))"
            cor = .green
        }

        self.init(
            titulo: participante.nomePessoa,
            subtitulo: subtitulo,
            valor: participante.valorPago,
            valorPrefixo: "Pagou ",
            valorCor: cor,
            // Inclui o total: depois de pago o header mostra o valor pago, não a conta.
            detalhes: Self.detalhesConta(participante, incluirTotal: true)
        )
    }

    // Detalhes de consumo de uma pessoa: itens + extras.
    private static func detalhesConta(_ participante: ParticipanteComanda, incluirTotal: Bool = false) -> [DetalheExpandivel] {
        var linhas = participante.itensConsumidos.map {
            DetalheExpandivel(texto: "\(Self.prefixoQuantidade(de: $0)) \($0.nome)", valor: $0.precoPorDono)
        }

        if participante.taxaServicoAtual > 0 {
            linhas.append(DetalheExpandivel(texto: "Taxa de serviço 10%", valor: participante.taxaServicoAtual))
        }

        if participante.couvertArtisticoAtual > 0 {
            linhas.append(DetalheExpandivel(texto: "Couvert artístico", valor: participante.couvertArtisticoAtual))
        }

        if incluirTotal {
            let total = linhas.reduce(0) { $0 + $1.valor }
            linhas.append(DetalheExpandivel(texto: "Total", valor: total))
        }
        return linhas
    }

    // Item dividido vira fração com um dono só, quantidade cheia.
    private static func prefixoQuantidade(de item: ItemPedido) -> String {
        let qtd = quantidade(de: item)
        return item.donos.count > 1 ? "\(qtd)/\(item.donos.count)" : "\(qtd)"
    }

    // Quantidade deduzida do preço unitário do item no cardápio.
    private static func quantidade(de item: ItemPedido) -> Int {
        guard let unitario = item.itemCardapio?.preco, unitario > 0 else { return 1 }
        return NSDecimalNumber(decimal: item.preco / unitario).intValue
    }
}

#Preview {
    let context = DadosDeExemplo.container.mainContext
    let comanda = (try? context.fetch(FetchDescriptor<Comanda>()))?.first
    let pedidos = comanda?.pedidos ?? []
    let participantes = comanda?.participantes ?? []

    // Simula pagamentos variados para ver quitado/deve/emprestou.
    let _ = {
        for (i, p) in participantes.enumerated() {
            switch i % 3 {
                case 0: p.valorPago = p.contaAtual
                case 1: p.valorPago = p.contaAtual / 2
                default: p.valorPago = p.contaAtual * 2
            }
        }
    }()

    ScrollView {
        VStack(spacing: 24) {
            // Fluxo dos pedidos.
            ForEach(pedidos) { pedido in
                RowExpandivel(pedido: pedido)
            }

            // Conta durante a comanda.
            ForEach(participantes) { participante in
                RowExpandivel(conta: participante)
            }

            // Conta pós-pagamento (quitado/deve/emprestou)
            ForEach(participantes) { participante in
                RowExpandivel(contaPaga: participante)
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

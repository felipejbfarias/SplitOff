//
//  ListaRowsPicker.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI

// O toque abre o menu do PickerSeletor ou um sheet externo
struct LinhaPicker: Identifiable {
    let id = UUID()
    let titulo: String
    var desabilitado: Bool = false
    let comportamento: Comportamento

    enum Comportamento {
        // Abre o menu do PickerSeletor e escreve na seleção.
        case picker(opcoes: [String], selecao: Binding<String?>, temAdicionar: Bool, acaoAdicionar: () -> Void)
        
        // Abre um sheet externo
        case sheet(rotulo: String, selecionado: Bool, acao: () -> Void)
    }
}

// Atalhos para montar as linhas sem repetir o enum.
extension LinhaPicker {
    static func picker(
        titulo: String,
        opcoes: [String],
        selecao: Binding<String?>,
        desabilitado: Bool = false,
        temAdicionar: Bool = false,
        acaoAdicionar: @escaping () -> Void = {}
    ) -> LinhaPicker {
        LinhaPicker(
            titulo: titulo,
            desabilitado: desabilitado,
            comportamento: .picker(opcoes: opcoes, selecao: selecao, temAdicionar: temAdicionar, acaoAdicionar: acaoAdicionar)
        )
    }

    static func sheet(
        titulo: String,
        rotulo: String = "Selecionar",
        selecionado: Bool = false,
        desabilitado: Bool = false,
        acao: @escaping () -> Void
    ) -> LinhaPicker {
        LinhaPicker(
            titulo: titulo,
            desabilitado: desabilitado,
            comportamento: .sheet(rotulo: rotulo, selecionado: selecionado, acao: acao)
        )
    }
}

// Card de linhas com seletor à direita
struct ListaRowsPicker: View {
    var titulo: String? = nil
    let linhas: [LinhaPicker]

    private let alturaRow: CGFloat = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let titulo {
                Text(titulo)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }

            cartao {
                ForEach(linhas) { linha in
                    row(linha)
                    if linha.id != linhas.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func row(_ linha: LinhaPicker) -> some View {
        HStack {
            Text(linha.titulo)
                .fontWeight(.medium)
                .foregroundStyle(linha.desabilitado ? .secondary : .primary)

            Spacer()

            switch linha.comportamento {
                case let .picker(opcoes, selecao, temAdicionar, acaoAdicionar):
                    PickerSeletor(
                        titulo: "Selecionar",
                        opcoes: opcoes,
                        selecao: selecao,
                        acaoAdicionar: acaoAdicionar,
                        tem: temAdicionar
                    )

                case let .sheet(rotulo, selecionado, acao):
                    botaoSheet(rotulo: rotulo, selecionado: selecionado, acao: acao)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: alturaRow)
        .disabled(linha.desabilitado)
    }

    // Reaproveita o PickerSeletor
    private func botaoSheet(rotulo: String, selecionado: Bool, acao: @escaping () -> Void) -> some View {
        PickerSeletor(
            titulo: rotulo,
            opcoes: [rotulo],
            selecao: .constant(selecionado ? rotulo : nil),
            acaoAdicionar: {},
            tem: false
        )
        .allowsHitTesting(false)
        .overlay {
            Button(action: acao) {
                Color.clear.contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    // Card
    private func cartao<Conteudo: View>(@ViewBuilder _ conteudo: () -> Conteudo) -> some View {
        VStack(spacing: 0) { conteudo() }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}

#Preview {
    @Previewable @State var lugar: String? = nil
    @Previewable @State var grupo: String? = nil

    ScrollView {
        ListaRowsPicker(
            titulo: "Informações",
            linhas: [
                .picker(
                    titulo: "Lugar",
                    opcoes: ["Bar do Pinto", "Mamute", "Paraibanos"],
                    selecao: $lugar,
                    temAdicionar: true,
                    acaoAdicionar: { print("Adicionar lugar") }
                ),
                .picker(
                    titulo: "Grupo",
                    opcoes: ["Família", "Trabalho", "Faculdade"],
                    selecao: $grupo,
                    temAdicionar: true,
                    acaoAdicionar: { print("Adicionar grupo") }
                ),
                .sheet(
                    titulo: "Pessoas do grupo",
                    desabilitado: grupo == nil,
                    acao: { print("Abrir SheetSelecionarPessoas") }
                )
            ]
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

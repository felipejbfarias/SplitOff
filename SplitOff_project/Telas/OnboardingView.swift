//
//  OnboardingView.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 11/07/26.
//

import SwiftUI

// Apresentação do primeiro uso: páginas deslizáveis mostrando o fluxo
struct OnboardingView: View {
    let aoConcluir: () -> Void

    @State private var pagina = 0

    private let paginas: [PaginaOnboarding] = [
        PaginaOnboarding(
            ilustracao: .imagem("maca_inteira"),
            titulo: "Crie sua comanda",
            descricao: "Saiu com a galera? Abra uma comanda, escolha o lugar e registre os seus pedidos, tudo em um só lugar."
        ),
        PaginaOnboarding(
            ilustracao: .imagem("maca_cortada"),
            titulo: "Divida com o grupo",
            descricao: "Adicione seus amigos e marque quem pediu cada item. Cada um paga só a parte dele, sem conta de cabeça."
        ),
        PaginaOnboarding(
            ilustracao: .simbolo("text.viewfinder"),
            titulo: "Escaneie o cardápio",
            descricao: "Fotografe o cardápio, ou escolha uma foto da galeria, e a Apple Intelligence preenche o resto pra você. Como a leitura é feita por IA, ela pode cometer erros: revise os nomes e preços antes de adicionar."
        ),
        PaginaOnboarding(
            ilustracao: .simbolo("arrow.left.arrow.right.circle"),
            titulo: "Quite as dívidas",
            descricao: "Veja quem deve pra quem e siga as sugestões de transferência pra zerar tudo com o menor número de transferências."
        ),
    ]

    private var ultimaPagina: Bool {
        pagina == paginas.count - 1
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                botaoPular

                TabView(selection: $pagina) {
                    ForEach(Array(paginas.enumerated()), id: \.offset) { indice, pagina in
                        PaginaOnboardingView(pagina: pagina)
                            .tag(indice)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                indicadores
                    .padding(.bottom, 16)

                BotaoSimples1(titulo: ultimaPagina ? "Começar" : "Continuar") {
                    if ultimaPagina {
                        aoConcluir()
                    } else {
                        withAnimation { pagina += 1 }
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    // Pular some na última página
    private var botaoPular: some View {
        HStack {
            Spacer()

            Button("Pular", action: aoConcluir)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .opacity(ultimaPagina ? 0 : 1)
                .animation(.easeInOut(duration: 0.2), value: ultimaPagina)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var indicadores: some View {
        HStack(spacing: 8) {
            ForEach(paginas.indices, id: \.self) { indice in
                Capsule()
                    .fill(indice == pagina ? Color.pink : Color(.systemGray4))
                    .frame(width: indice == pagina ? 24 : 8, height: 8)
            }
        }
        .animation(.snappy, value: pagina)
    }
}

private struct PaginaOnboarding {
    enum Ilustracao {
        case imagem(String)
        case simbolo(String)
    }

    let ilustracao: Ilustracao
    let titulo: String
    let descricao: String
}

private struct PaginaOnboardingView: View {
    let pagina: PaginaOnboarding

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ilustracao
                .frame(height: 220)

            VStack(spacing: 12) {
                Text(pagina.titulo)
                    .font(.system(size: 28, weight: .bold))

                Text(pagina.descricao)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    @ViewBuilder
    private var ilustracao: some View {
        switch pagina.ilustracao {
        case .imagem(let nome):
            Image(nome)
                .resizable()
                .scaledToFit()
                .frame(width: 220)
        case .simbolo(let nome):
            Image(systemName: nome)
                .font(.system(size: 130))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.accent)
        }
    }
}

#Preview {
    OnboardingView {}
}

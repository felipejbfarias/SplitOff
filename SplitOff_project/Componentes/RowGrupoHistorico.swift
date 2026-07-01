//
//  RowGrupoHistorico.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//

import SwiftUI
import SwiftData

// Toca para abrir e arrasta para a esquerda para revelar Remover.
struct RowGrupoHistorico: View {
    var foto: Data? = nil
    var mostrafotoGrupo: Bool = false
    let titulo: String
    var subtitulo: String? = nil
    var subtitulo2: String? = nil
    var data: Date? = nil
    var aoTocar: () -> Void
    var aoRemover: () -> Void

    @State private var offset: CGFloat = 0
    @State private var comprometido: CGFloat = 0
    private let larguraRemover: CGFloat = 80

    var body: some View {
        ZStack(alignment: .trailing) {
            botaoRemover
            cartao
                .offset(x: offset)
                .gesture(arraste)
        }
    }

    // Card por cima
    private var cartao: some View {
        HStack(spacing: 12) {
            if mostrafotoGrupo { fotoGrupo }

            VStack(alignment: .leading, spacing: 2) {
                Text(titulo)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if let subtitulo {
                    Text(subtitulo)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let subtitulo2 {
                    Text(subtitulo2)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let data {
                Text(dataFormatada(data))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
        .contentShape(.rect)
        .onTapGesture {
            if offset < 0 { fechar() } else { aoTocar() }
        }
    }

    // Foto do grupo: foto quando existe, senão o ícone padrão de pessoa
    private var fotoGrupo: some View {
        Group {
            if let foto, let imagem = UIImage(data: foto) {
                Image(uiImage: imagem)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(.circle)
    }

    // Botão atrás do card (Remover)
    private var botaoRemover: some View {
        Button {
            fechar()
            aoRemover()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "trash.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.red, in: .circle)
                Text("Remover")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(width: larguraRemover)
        .opacity(offset < 0 ? 1 : 0)
    }

    // Arraste só para a esquerda
    private var arraste: some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { valor in
                offset = min(0, max(-larguraRemover, valor.translation.width + comprometido))
            }
            .onEnded { _ in
                withAnimation(.snappy) {
                    offset = offset < -larguraRemover / 2 ? -larguraRemover : 0
                    comprometido = offset
                }
            }
    }

    private func fechar() {
        withAnimation(.snappy) {
            offset = 0
            comprometido = 0
        }
    }

    // Data em pt-BR
    private func dataFormatada(_ data: Date) -> String {
        let locale = Locale(identifier: "pt_BR")
        let dia = data.formatted(.dateTime.day().locale(locale))
        let mes = data.formatted(.dateTime.month(.wide).locale(locale)).capitalized(with: locale)
        return "\(dia) de \(mes)"
    }
}

extension RowGrupoHistorico {
    // Card de grupo, leva para a tela do grupo.
    init(grupo: Grupo, aoTocar: @escaping () -> Void, aoRemover: @escaping () -> Void) {
        self.init(
            foto: grupo.foto,
            mostrafotoGrupo: true,
            titulo: grupo.nome,
            aoTocar: aoTocar,
            aoRemover: aoRemover
        )
    }

    // Card de comanda, o grupo vai numa 3ª linha.
    init(
        comanda: Comanda,
        incluirGrupo: Bool = false,
        aoTocar: @escaping () -> Void,
        aoRemover: @escaping () -> Void
    ) {
        self.init(
            titulo: comanda.nome,
            subtitulo: comanda.restaurante?.nome,
            subtitulo2: incluirGrupo ? comanda.grupo?.nome : nil,
            data: comanda.data,
            aoTocar: aoTocar,
            aoRemover: aoRemover
        )
    }
}

#Preview {
    @Previewable @State var grupos: [Grupo] = []
    @Previewable @State var comandas: [Comanda] = []
    @Previewable @State var grupoParaApagar: Grupo?
    @Previewable @State var comandaParaApagar: Comanda?
    let context = DadosDeExemplo.container.mainContext
    let crud = CRUD(context: context)

    ZStack {
        ScrollView {
            VStack(spacing: 12) {
                // Grupo
                ForEach(grupos) { grupo in
                    RowGrupoHistorico(grupo: grupo) {} aoRemover: { grupoParaApagar = grupo }
                }

                // Comanda no histórico do grupo
                ForEach(comandas) { comanda in
                    RowGrupoHistorico(comanda: comanda) {} aoRemover: { comandaParaApagar = comanda }
                }

                // Comanda em todas as comandas
                ForEach(comandas) { comanda in
                    RowGrupoHistorico(comanda: comanda, incluirGrupo: true) {} aoRemover: { comandaParaApagar = comanda }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))

        // Popup destrutivo apresentado pela tela
        if let grupo = grupoParaApagar {
            PopUPDestrutivo.apagarGrupo(grupo) {
                try? crud.removerGrupo(grupo)
                grupos.removeAll { $0.id == grupo.id }
                grupoParaApagar = nil
            } aoCancelar: {
                grupoParaApagar = nil
            }
        }

        if let comanda = comandaParaApagar {
            PopUPDestrutivo.apagarComanda(comanda) {
                try? crud.removerComanda(comanda)
                comandas.removeAll { $0.id == comanda.id }
                comandaParaApagar = nil
            } aoCancelar: {
                comandaParaApagar = nil
            }
        }
    }
    .onAppear {
        grupos = (try? context.fetch(FetchDescriptor<Grupo>())) ?? []
        comandas = (try? context.fetch(FetchDescriptor<Comanda>())) ?? []
    }
}

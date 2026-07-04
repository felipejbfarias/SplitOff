//
//  PickerSeletor.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 26/06/26.
//


//Como passar o PickerSeletor:
//
//PickerSeletor(
//            titulo: "Lugar",
//            opcoes: lugares,
//            selecao: $lugarSelecionado
//        ) {
//
//            print("Abrir Sheet")
//
//        }



import SwiftUI

struct PickerSeletor: View {
    let titulo: String
    let opcoes: [String]
    @Binding var selecao: String?
    let acaoAdicionar: () -> Void
    var cor : Color {
        selecao == nil ? .secondary : .primary
    }
    let tem: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(selecao ?? titulo)
                .lineLimit(1)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2.weight(.bold))
        }
        .foregroundStyle(cor)
        .animation(.snappy, value: selecao)
        .contentShape(.rect)
        .overlay {
            Menu {
                ForEach(opcoes, id: \.self) { opcao in
                    Button {
                        withAnimation(.snappy) { selecao = opcao }
                    } label: {
                        if selecao == opcao {
                            Label(opcao, systemImage: "checkmark")
                        } else {
                            Text(opcao)
                        }
                    }
                }

                if tem {
                    Divider()
                    Button("Adicionar", action: acaoAdicionar)
                }
            } label: {
                Color.clear
            }
        }
    }
}


#Preview {

    struct PreviewWrapper: View {

        @State private var lugarSelecionado: String? = nil

        let lugares = [
            "Bar do Pinto",
            "Mamute",
            "Paraibanos",
            "Tio Armênio"
        ]

        var body: some View {

            PickerSeletor(
                titulo: "Lugar",
                opcoes: lugares,
                selecao: $lugarSelecionado,
                acaoAdicionar: {
                    print("Abrir Sheet")
                },
                tem: true
            )

        }

    }

    return PreviewWrapper()

}


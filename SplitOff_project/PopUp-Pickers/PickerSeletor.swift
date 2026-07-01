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
//    @Binding var selecao: String
    @State private var selecao: String? = nil
    let acaoAdicionar: () -> Void
    var cor : Color {
        selecao == nil ? .secondary : .primary
    }
    let tem: Bool

    var body: some View {
        
        HStack {
            if selecao == nil {
                Text(titulo)
                    .font(.headline)
                    .padding(.horizontal, -14)
                    .foregroundStyle(.secondary)
                    
            }
            Picker(titulo, selection: $selecao) {
                //            Text(titulo)
                //                .tag(nil as String?)
                ForEach(opcoes, id: \.self) { opcao in
                    Text(opcao)
                        .tag(opcao)
                }
                if tem {
                    Divider()
                    
                    Button {
                        acaoAdicionar()
                    } label: {
                        Text("Adicionar")
                    }
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
                }
            }
            .tint(cor)
        }
    }
}


#Preview {

    struct PreviewWrapper: View {

        @State private var lugarSelecionado = ""

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
                acaoAdicionar: {
                    print("Abrir Sheet")
                },
                tem: true
            )

        }

    }

    return PreviewWrapper()

}


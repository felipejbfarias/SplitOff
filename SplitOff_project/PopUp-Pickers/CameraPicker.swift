//
//  CameraPicker.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 12/07/26.
//

import SwiftUI

// Câmera do sistema para fotografar o cardápio na hora.
struct CameraPicker: UIViewControllerRepresentable {
    let aoCapturar: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    // Sem câmera a opção nem aparece.
    static var disponivel: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordenador {
        Coordenador(self)
    }

    final class Coordenador: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let picker: CameraPicker

        init(_ picker: CameraPicker) {
            self.picker = picker
        }

        func imagePickerController(
            _ controlador: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let imagem = info[.originalImage] as? UIImage {
                picker.aoCapturar(imagem)
            }
            picker.dismiss()
        }

        func imagePickerControllerDidCancel(_ controlador: UIImagePickerController) {
            picker.dismiss()
        }
    }
}

//
//  LeitorTextoCardapio.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 12/07/26.
//

import UIKit
import Vision

// Lê o texto de uma foto de cardápio com OCR
enum LeitorTextoCardapio {
    // Fragmento reconhecido, em coordenadas normalizadas
    private struct Fragmento {
        let texto: String
        let caixa: CGRect
        let topoEsquerdo: CGPoint
        let topoDireito: CGPoint
    }

    static func lerLinhas(de imagem: UIImage) async throws -> [String] {
        guard let cgImage = imagemNormalizada(de: imagem) else {
            throw ScannerCardapioErro.imagemInvalida
        }

        var requisicao = RecognizeTextRequest()
        requisicao.recognitionLevel = .accurate
        requisicao.recognitionLanguages = [Locale.Language(identifier: "pt-BR")]
        requisicao.usesLanguageCorrection = true

        let observacoes = try await requisicao.perform(on: cgImage)

        let fragmentos = observacoes.compactMap { observacao -> Fragmento? in
            guard let texto = observacao.topCandidates(1).first?.string else { return nil }
            return Fragmento(
                texto: texto,
                caixa: observacao.boundingBox.cgRect,
                topoEsquerdo: CGPoint(x: observacao.topLeft.x, y: observacao.topLeft.y),
                topoDireito: CGPoint(x: observacao.topRight.x, y: observacao.topRight.y)
            )
        }

        // Proporção da imagem, converte distâncias normalizadas em distâncias reais.
        let proporcao = Double(cgImage.width) / Double(cgImage.height)
        let angulo = estimarAngulo(fragmentos, proporcao: proporcao)

        // Cardápio de página inteira costuma ter duas colunas: agrupar sem separar mistura pratos da esquerda com preços da direita na mesma linha.
        return dividirEmColunas(fragmentos).flatMap {
            agruparEmLinhas($0, anguloGraus: angulo, proporcao: proporcao)
        }
    }

    // Procura um corte vertical que separe colunas
    private static func dividirEmColunas(_ fragmentos: [Fragmento], niveis: Int = 1) -> [[Fragmento]] {
        guard niveis >= 0, fragmentos.count >= 24 else { return [fragmentos] }

        var melhor: (corte: Double, cruzando: Int)?
        for corte in stride(from: 0.3, through: 0.7, by: 0.01) {
            let cruzando = fragmentos.count { $0.caixa.minX < corte && $0.caixa.maxX > corte }
            guard cruzando <= max(1, fragmentos.count / 20) else { continue }

            let esquerda = fragmentos.filter { $0.caixa.midX < corte }
            let direita = fragmentos.filter { $0.caixa.midX >= corte }
            guard esquerda.count >= fragmentos.count / 5,
                  direita.count >= fragmentos.count / 5,
                  pareceColuna(esquerda),
                  pareceColuna(direita)
            else { continue }

            if melhor == nil || cruzando < melhor!.cruzando {
                melhor = (corte, cruzando)
            }
        }

        guard let corte = melhor?.corte else { return [fragmentos] }

        return dividirEmColunas(fragmentos.filter { $0.caixa.midX < corte }, niveis: niveis - 1)
            + dividirEmColunas(fragmentos.filter { $0.caixa.midX >= corte }, niveis: niveis - 1)
    }

    // Fragmento que é só preço ("R$ 62 / R$ 74", "25,90").
    private static let textoSoPreco = try! Regex(
        #"^\s*(?:R\$\s*)?\d{1,4}(?:[.,]\d{1,3})?(?:\s*/\s*(?:R\$\s*)?\d{1,4}(?:[.,]\d{1,3})?)*\s*$"#
    )

    // Uma coluna de verdade tem preços próprios e também nomes/descrições. Sem os dois lados dessa moeda, o corte separou nome de preço dentro de uma coluna.
    private static func pareceColuna(_ fragmentos: [Fragmento]) -> Bool {
        let precos = fragmentos.count { $0.texto.firstMatch(of: textoSoPreco) != nil }
        return precos >= 2 && Double(precos) < Double(fragmentos.count) * 0.6
    }

    // Redesenha a foto aplicando a orientação e limitando o tamanho
    private static func imagemNormalizada(de imagem: UIImage, ladoMaximo: CGFloat = 2200) -> CGImage? {
        let maiorLado = max(imagem.size.width, imagem.size.height)
        guard maiorLado > 0 else { return nil }

        let escala = min(1, ladoMaximo / maiorLado)
        let tamanho = CGSize(width: imagem.size.width * escala, height: imagem.size.height * escala)

        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1

        let redesenhada = UIGraphicsImageRenderer(size: tamanho, format: formato).image { _ in
            imagem.draw(in: CGRect(origin: .zero, size: tamanho))
        }
        return redesenhada.cgImage
    }

    // Correção de inclinação
    private static func yCorrigido(_ caixa: CGRect, tangente: Double, proporcao: Double) -> Double {
        caixa.midY - caixa.midX * tangente * proporcao
    }

    private static func estimarAngulo(_ fragmentos: [Fragmento], proporcao: Double) -> Double {
        let grosso = anguloPorCantos(fragmentos, proporcao: proporcao)

        var melhorAngulo = grosso
        var maisPares = -1
        for candidato in stride(from: grosso - 2.5, through: grosso + 2.5, by: 0.25) {
            let pares = paresAlinhados(fragmentos, anguloGraus: candidato, proporcao: proporcao)
            // Empate favorece o ângulo de menor módulo
            if pares > maisPares || (pares == maisPares && abs(candidato) < abs(melhorAngulo)) {
                maisPares = pares
                melhorAngulo = candidato
            }
        }
        return melhorAngulo
    }

    private static func anguloPorCantos(_ fragmentos: [Fragmento], proporcao: Double) -> Double {
        let medidas = fragmentos.compactMap { fragmento -> (angulo: Double, peso: Double)? in
            let dx = (fragmento.topoDireito.x - fragmento.topoEsquerdo.x) * proporcao
            let dy = fragmento.topoDireito.y - fragmento.topoEsquerdo.y
            // Fragmentos estreitos medem mal o ângulo
            guard dx > 0.01 else { return nil }
            return (atan2(dy, dx) * 180 / .pi, dx)
        }
        guard !medidas.isEmpty else { return 0 }

        let ordenadas = medidas.sorted { $0.angulo < $1.angulo }
        let metadeDoPeso = ordenadas.map(\.peso).reduce(0, +) / 2
        var acumulado = 0.0
        for medida in ordenadas {
            acumulado += medida.peso
            if acumulado >= metadeDoPeso { return medida.angulo }
        }
        return ordenadas.last?.angulo ?? 0
    }

    // Pares de fragmentos com ΔY corrigido menor que a meia altura
    private static func paresAlinhados(_ fragmentos: [Fragmento], anguloGraus: Double, proporcao: Double) -> Int {
        let tangente = tan(anguloGraus * .pi / 180)
        let centros = fragmentos.map {
            (y: yCorrigido($0.caixa, tangente: tangente, proporcao: proporcao), altura: $0.caixa.height)
        }

        var pares = 0
        for i in centros.indices {
            for j in (i + 1) ..< centros.count
            where abs(centros[i].y - centros[j].y) < min(centros[i].altura, centros[j].altura) * 0.5 {
                pares += 1
            }
        }
        return pares
    }

    // Junta fragmentos com centro vertical corrigido próximo em uma única linha, ordenados da esquerda para a direita
    private static func agruparEmLinhas(
        _ fragmentos: [Fragmento],
        anguloGraus: Double,
        proporcao: Double
    ) -> [String] {
        let tangente = tan(anguloGraus * .pi / 180)

        func centro(_ fragmento: Fragmento) -> Double {
            yCorrigido(fragmento.caixa, tangente: tangente, proporcao: proporcao)
        }

        // De cima para baixo
        let ordenados = fragmentos.sorted { centro($0) > centro($1) }

        var linhas: [[Fragmento]] = []
        for fragmento in ordenados {
            if var atual = linhas.last, let referencia = atual.first,
               abs(centro(fragmento) - centro(referencia)) < max(referencia.caixa.height, fragmento.caixa.height) * 0.6 {
                atual.append(fragmento)
                linhas[linhas.count - 1] = atual
            } else {
                linhas.append([fragmento])
            }
        }

        return linhas.map { linha in
            linha.sorted { $0.caixa.minX < $1.caixa.minX }
                .map(\.texto)
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)
        }
        .filter { !$0.isEmpty }
    }
}

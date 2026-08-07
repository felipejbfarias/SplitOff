//
//  ExtratorItensCardapio.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 12/07/26.
//

import UIKit
import FoundationModels

// Item lido da foto, aguardando revisão do usuário antes de entrar no cardápio.
struct ItemEscaneado: Identifiable, Hashable {
    let id: UUID
    var nome: String
    var preco: Decimal

    init(id: UUID = UUID(), nome: String, preco: Decimal) {
        self.id = id
        self.nome = nome
        self.preco = preco
    }
}

enum ScannerCardapioErro: LocalizedError {
    case imagemInvalida
    case semTexto
    case nenhumItem

    var errorDescription: String? {
        switch self {
        case .imagemInvalida:
            return "Não foi possível ler essa imagem."
        case .semTexto:
            return "Nenhum texto foi encontrado na foto. Tente uma foto mais nítida e bem iluminada."
        case .nenhumItem:
            return "Não achei itens com preço nessa foto. Tente enquadrar a parte do cardápio com os preços."
        }
    }
}

// O modelo do Apple Intelligence é obrigado a responder neste formato.
@Generable
private struct CardapioGerado {
    @Guide(description: "Itens de comida ou bebida do cardápio que têm preço")
    var itens: [ItemGerado]
}

@Generable
private struct ItemGerado {
    @Guide(description: "Nome do item como escrito no cardápio, sem a descrição dos ingredientes")
    var nome: String

    // Preço como texto copiado, não como número
    @Guide(
        description: "Preço do item copiado exatamente do texto, com vírgula nos centavos. Exemplo: 26,99",
        .pattern(#/\d{1,4}(\.\d{3})?(,\d{1,2})?/#)
    )
    var preco: String
}

// Transforma a foto de um cardápio em itens estruturados: OCR com o Vision e, com Apple Intelligence disponível, o modelo on-device organiza nome + preço. Sem Apple Intelligence, cai para um leitor de preços por padrão de texto.

enum ExtratorItensCardapio {
    // O modelo on-device existe e está pronto
    static var inteligenciaDisponivel: Bool {
        SystemLanguageModel.default.availability == .available
    }

    // Extrai os itens da foto. `aoAtualizar` recebe, a cada avanço do streaming do modelo
    static func extrair(
        de imagem: UIImage,
        aoAtualizar: ([ItemEscaneado]) -> Void = { _ in }
    ) async throws -> [ItemEscaneado] {
        let linhas = try await LeitorTextoCardapio.lerLinhas(de: imagem)
        guard !linhas.isEmpty else { throw ScannerCardapioErro.semTexto }

        var itens: [ItemEscaneado] = []
        if inteligenciaDisponivel {
            do {
                itens = try await extrairComModelo(linhas, aoAtualizar: aoAtualizar)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                itens = []
            }
        }
        if itens.isEmpty {
            itens = extrairComHeuristica(linhas)
        }

        let unicos = removerDuplicados(itens)
        guard !unicos.isEmpty else { throw ScannerCardapioErro.nenhumItem }
        return unicos
    }

    private static func extrairComModelo(
        _ linhas: [String],
        aoAtualizar: ([ItemEscaneado]) -> Void
    ) async throws -> [ItemEscaneado] {
        let instrucoes = """
        Você extrai itens de cardápios de restaurantes e bares brasileiros.
        O texto vem do OCR de uma foto, então pode conter erros e fragmentos soltos.
        Extraia apenas itens de comida ou bebida que tenham preço no texto.
        O nome de um item pode ocupar mais de uma linha; junte as partes.
        Copie o preço exatamente como está no texto, mantendo a vírgula: "R$ 26,99" vira "26,99".
        Um item com vários preços separados por "/" tem um preço por tamanho, na ordem do título da seção: crie um item para cada tamanho, com o tamanho entre parênteses no nome. Se os nomes dos tamanhos não estiverem no texto, use "(opção 1)", "(opção 2)".
        Gramaturas e volumes como 150g, 250g ou 350ml não são preços.
        Ignore títulos de seção, descrições de ingredientes, taxas de serviço e textos promocionais.
        Não invente itens nem preços que não estão no texto.

        Exemplo. Texto:
        Pizzas (Média / Grande)
        Calabresa R$ 62 / R$ 74
        Calabresa, muçarela, molho de tomate e orégano.
        X-Salada ..... R$ 18,50
        Batata Belga (M) com ou sem
        páprica defumada ou picante
        250g (M), com Páprica + um molho.
        R$ 26,99
        Itens extraídos: "Calabresa (Média)" preço "62", "Calabresa (Grande)" preço "74", "X-Salada" preço "18,50" e "Batata Belga (M) com ou sem páprica defumada ou picante" preço "26,99".
        """

        var confirmados: [ItemEscaneado] = []

        for bloco in dividirEmBlocos(linhas, tamanho: 40) {
            // Sessão nova por bloco: o histórico de um bloco não consome o contexto do próximo.
            let sessao = LanguageModelSession(instructions: instrucoes)
            let fluxo = sessao.streamResponse(
                to: "Extraia os itens deste cardápio:\n\(bloco.joined(separator: "\n"))",
                generating: CardapioGerado.self,
                options: GenerationOptions(sampling: .greedy)
            )

            // Cada snapshot repete a lista inteira do bloco, então o id de cada posição é reaproveitado.
            var idsDoBloco: [UUID] = []
            var ultimoSnapshot: [ItemGerado.PartiallyGenerated] = []

            for try await parcial in fluxo {
                ultimoSnapshot = parcial.content.itens ?? []
                let prontos = converter(ultimoSnapshot.dropLast(), ids: &idsDoBloco)
                aoAtualizar(removerDuplicados(confirmados + prontos))
            }

            confirmados += converter(ultimoSnapshot, ids: &idsDoBloco)
        }

        return confirmados
    }

    // Converte itens parciais do modelo em itens escaneados, reaproveitando o id de cada posição.
    private static func converter(
        _ gerados: some Collection<ItemGerado.PartiallyGenerated>,
        ids: inout [UUID]
    ) -> [ItemEscaneado] {
        var itens: [ItemEscaneado] = []
        for (indice, gerado) in gerados.enumerated() {
            if indice >= ids.count { ids.append(UUID()) }

            guard let nome = gerado.nome?.trimmingCharacters(in: .whitespacesAndNewlines),
                  nome.count >= 2,
                  let textoPreco = gerado.preco,
                  let preco = decimalDoTexto(textoPreco),
                  preco < 100_000
            else { continue }

            itens.append(ItemEscaneado(id: ids[indice], nome: nome, preco: preco))
        }
        return itens
    }

    // Um item de "cartão" (nome, descrição e preço em linhas separadas) que cair na fronteira aparece inteiro no bloco seguinte
    private static func dividirEmBlocos(_ linhas: [String], tamanho: Int, sobreposicao: Int = 6) -> [[String]] {
        let passo = max(1, tamanho - sobreposicao)
        var blocos: [[String]] = []
        var inicio = 0
        while inicio < linhas.count {
            let fim = min(inicio + tamanho, linhas.count)
            blocos.append(Array(linhas[inicio ..< fim]))
            if fim == linhas.count { break }
            inicio += passo
        }
        return blocos
    }

    // Um ou mais preços no fim da linha
    private static let padraoPrecosNoFim = try! Regex(
        #"((?:R\$\s*)?\d{1,4}(?:\.\d{3})*(?:[.,]\d{1,2})?(?:\s*/\s*(?:R\$\s*)?\d{1,4}(?:\.\d{3})*(?:[.,]\d{1,2})?)*)\s*$"#
    )

    // Números sem separador decimal só valem com o "R$" explícito
    private static let precoValido = try! Regex(
        #"^(?:R\$\s*\d{1,4}(?:[.,]\d{1,2})?|\d{1,4}(?:\.\d{3})*,\d{2}|\d{1,4}\.\d{2})$"#
    )

    private static func extrairComHeuristica(_ linhas: [String]) -> [ItemEscaneado] {
        linhas.flatMap { linha -> [ItemEscaneado] in
            guard let combinacao = linha.firstMatch(of: padraoPrecosNoFim),
                  let trecho = combinacao.output[1].substring
            else { return [] }

            // Todos os trechos entre "/" precisam ser preços de verdade.
            let partes = trecho.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
            guard !partes.isEmpty, partes.allSatisfy({ $0.firstMatch(of: precoValido) != nil }) else { return [] }

            let precos = partes.compactMap { parte in
                decimalDoTexto(parte.replacingOccurrences(of: "R$", with: "").trimmingCharacters(in: .whitespaces))
            }
            guard precos.count == partes.count else { return [] }

            // Nome = linha sem os preços, aparando pontilhados e traços de preenchimento.
            var nome = String(linha[..<combinacao.range.lowerBound])
            nome = nome.trimmingCharacters(in: CharacterSet(charactersIn: " .·•–—-_…:/\t"))
            guard nome.count >= 3, nome.contains(where: \.isLetter) else { return [] }

            if precos.count == 1 {
                return [ItemEscaneado(nome: nome, preco: precos[0])]
            }
            // Sem o título da seção não dá para saber os tamanhos; o usuário renomeia na revisão.
            return precos.enumerated().map { indice, preco in
                ItemEscaneado(nome: "\(nome) (opção \(indice + 1))", preco: preco)
            }
        }
    }

    // Converte para Decimal.
    private static func decimalDoTexto(_ texto: String) -> Decimal? {
        var normalizado = texto
        if normalizado.contains(",") {
            normalizado = normalizado
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        }
        guard let valor = Decimal(string: normalizado), valor >= 0 else { return nil }
        return valor
    }

    // O OCR pode ler o mesmo item duas vezes, mantém a primeira ocorrência de cada nome.
    private static func removerDuplicados(_ itens: [ItemEscaneado]) -> [ItemEscaneado] {
        var vistos: Set<String> = []
        return itens.filter { vistos.insert(chaveDoNome($0.nome)).inserted }
    }

    static func chaveDoNome(_ nome: String) -> String {
        nome.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
            .trimmingCharacters(in: .whitespaces)
    }
}

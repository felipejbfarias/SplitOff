import Foundation
import SwiftData

// Dados fictícios usados nos #Preview.
enum DadosDeExemplo {

    // Container em memória já populado, para previews.
    @MainActor
    static let container: ModelContainer = {
        let schema = Schema(splitOffModels)
        let configuracao = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuracao])
            popular(em: container.mainContext)
            return container
        } catch {
            fatalError("Falha ao criar o container de exemplo: \(error)")
        }
    }()

    // Insere um cenário completo: grupo, pessoas, restaurante, cardápio e uma comanda ativa.
    @MainActor
    static func popular(em context: ModelContext) {
        let crud = CRUD(context: context)

        do {
            let grupo = try crud.criarGrupo(nome: "Amigos da Facul")

            let ana = try crud.criarPessoa(nome: "Ana", grupo: grupo)
            let bruno = try crud.criarPessoa(nome: "Bruno", grupo: grupo)
            let carla = try crud.criarPessoa(nome: "Carla", grupo: grupo)

            let restaurante = try crud.criarLugar(nome: "Cantina da Esquina")
            guard let cardapio = restaurante.cardapio else { return }

            let parmegiana = try crud.criarItem(nome: "Parmegiana", preco: 48, cardapio: cardapio)
            let coca = try crud.criarItem(nome: "Coca-Cola", preco: 9, cardapio: cardapio)
            _ = try crud.criarItem(nome: "Batata Frita", preco: 25, cardapio: cardapio)

            let comanda = try crud.criarComanda(nome: "Jantar de sexta", grupo: grupo, restaurante: restaurante)

            let pAna = try crud.adicionarParticipante(ana, a: comanda)
            let pBruno = try crud.adicionarParticipante(bruno, a: comanda)
            let pCarla = try crud.adicionarParticipante(carla, a: comanda)

            let pedido = try crud.criarPedido(comanda: comanda)
            _ = try crud.criarItemPedido(itemCardapio: parmegiana, quantidade: 1, pedido: pedido, donos: [pAna, pBruno])
            _ = try crud.criarItemPedido(itemCardapio: coca, quantidade: 1, pedido: pedido, donos: [pBruno, pCarla])
        } catch {
            assertionFailure("Falha ao popular dados de exemplo: \(error)")
        }
    }
}

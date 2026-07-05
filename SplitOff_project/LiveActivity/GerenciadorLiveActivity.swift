//
//  GerenciadorLiveActivity.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 04/07/26.
//

import Foundation
import ActivityKit

// Liga o ciclo de vida da Live Activity ao da comanda ativa: começa quando ela existe, atualiza quando os valores mudam e encerra quando fecha.
@MainActor
enum GerenciadorLiveActivity {
    private static var atividade: Activity<ComandaAtividadeAttributes>?

    // Começa ou atualiza a atividade espelhando a comanda ativa.
    static func sincronizar(com comanda: Comanda) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if atividade == nil {
            atividade = Activity<ComandaAtividadeAttributes>.activities.first
        }

        let estado = ComandaAtividadeAttributes.ContentState(
            gastoVoce: comanda.gastoDoVoce ?? 0,
            totalMesa: comanda.valorTotal
        )

        if let atividade {
            Task { await atividade.update(ActivityContent(state: estado, staleDate: nil)) }
            return
        }

        let atributos = ComandaAtividadeAttributes(
            nomeEvento: comanda.nome,
            nomeLugar: comanda.restaurante?.nome ?? comanda.nome
        )

        atividade = try? Activity.request(
            attributes: atributos,
            content: ActivityContent(state: estado, staleDate: nil)
        )
    }

    // Encerra e some da tela quando a comanda fecha.
    static func encerrar() {
        let atividades = Activity<ComandaAtividadeAttributes>.activities
        guard !atividades.isEmpty else { return }

        Task {
            for atividade in atividades {
                await atividade.end(nil, dismissalPolicy: .immediate)
            }
        }
        atividade = nil
    }
}

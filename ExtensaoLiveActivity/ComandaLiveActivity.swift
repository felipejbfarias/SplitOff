//
//  ComandaLiveActivity.swift
//  ExtensaoLiveActivity
//
//  Created by Matheus Miranda Cabral de Menezes on 04/07/26.
//

import WidgetKit
import SwiftUI
import ActivityKit

// Live Activity da comanda ativa. Tocar em qualquer apresentação abre o app,
// que já cai na Comanda Atual (a raiz mostra ela sempre que existe comanda ativa).
struct ComandaLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ComandaAtividadeAttributes.self) { contexto in
            // Tela bloqueada: o card completo sobre vidro translúcido, não preto.
            LiveActivitiesTelaBloqueio(
                nomeEvento: contexto.attributes.nomeEvento,
                nomeLugar: contexto.attributes.nomeLugar,
                gastoVoce: contexto.state.gastoVoce,
                totalMesa: contexto.state.totalMesa
            )
            .activityBackgroundTint(Color.white.opacity(0.15))
        } dynamicIsland: { contexto in
            DynamicIsland {
                // Segurar a ilha expande para o mesmo card do bloqueio.
                DynamicIslandExpandedRegion(.center) {
                    LiveActivitiesTelaBloqueio(
                        nomeEvento: contexto.attributes.nomeEvento,
                        nomeLugar: contexto.attributes.nomeLugar,
                        gastoVoce: contexto.state.gastoVoce,
                        totalMesa: contexto.state.totalMesa
                    )
                }
            } compactLeading: {
                // A ilha compacta é simétrica: o lado maior define os dois.
                // Conteúdo curto dos dois lados = ilha pequena, estilo iFood/99.
                Image(systemName: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(.pink)
            } compactTrailing: {
                LiveActivitiesTelaDesbloqueada(
                    gastoVoce: contexto.state.gastoVoce,
                    mostrarIcone: false
                )
            } minimal: {
                Image(systemName: "person.fill")
                    .font(.footnote)
                    .foregroundStyle(.pink)
            }
        }
    }
}

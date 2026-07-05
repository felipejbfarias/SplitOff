//
//  ComandaAtividadeAttributes.swift
//  SplitOff_project
//
//  Created by Matheus Miranda Cabral de Menezes on 04/07/26.
//

import Foundation
import ActivityKit

// Dados da Live Activity da comanda ativa.
struct ComandaAtividadeAttributes: ActivityAttributes {
    // Fixos
    var nomeEvento: String
    var nomeLugar: String

    // Atualizam ao vivo conforme a comanda anda.
    struct ContentState: Codable, Hashable {
        var gastoVoce: Decimal
        var totalMesa: Decimal
    }
}

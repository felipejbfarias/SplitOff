//
//  ExtensaoLiveActivityBundle.swift
//  ExtensaoLiveActivity
//
//  Created by Matheus Miranda Cabral de Menezes on 04/07/26.
//

import WidgetKit
import SwiftUI

// Ponto de entrada da extensão: registra a Live Activity da comanda.
@main
struct ExtensaoLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        ComandaLiveActivity()
    }
}

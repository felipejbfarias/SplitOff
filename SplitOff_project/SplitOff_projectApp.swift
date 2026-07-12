//
//  SplitOff_projectApp.swift
//  SplitOff_project
//
//  Created by Felipe José Batista Farias on 6/25/26.
//.

import SwiftUI
import SwiftData

@main
struct SplitOff_projectApp: App {
    @AppStorage("onboardingConcluido") private var onboardingConcluido = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                TabBarManager()

                if !onboardingConcluido {
                    OnboardingView {
                        withAnimation(.easeOut(duration: 0.35)) {
                            onboardingConcluido = true
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .modelContainer(Persistencia.container)
    }
}

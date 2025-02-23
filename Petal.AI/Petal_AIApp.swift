//
//  Petal_AIApp.swift
//  Petal.AI
//
//  Created by Nick on 3/1/25.
//

import SwiftUI

@main
struct Petal_AIApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // Save any pending state and perform cleanup
                UserDefaults.standard.synchronize()
            }
        }
    }
}

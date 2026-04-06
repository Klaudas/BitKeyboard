//
//  RootView.swift
//  BitKeyboard
//
//  Created by klaudas on 03/04/2026.
//

import SwiftUI

@main
struct RootView: App {

    enum RootState {
        case none
        case welcome
        case content
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var state: RootState = .none
    private let permissionService = PermissionService()

    var body: some Scene {
        WindowGroup {
            Group {
                switch state {
                case .none:
                    EmptyView()
                case .welcome:
                    WelcomeView()
                case .content:
                    ContentView()
                }
            }
            .environmentObject(permissionService)
            .onAppear {
                handleNavigation()
            }
        }
    }

    private func handleNavigation() {
        guard state == .none else { return }
        let mapper = SymbolSecureMapper()
        try? mapper.generateSealedSymbolIDs()
        
        permissionService.refresh()
        state = permissionService.isKeyboardFullyEnabled ? .content : .welcome
    }

}

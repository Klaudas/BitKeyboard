//
//  WelcomeView.swift
//  BitKeyboard
//
//  Created by klaudas on 04/04/2026.
//

import SwiftUI

struct WelcomeView: View {

    @EnvironmentObject private var permissionService: PermissionService

    var body: some View {
        VStack(spacing: .xlarge) {
            Spacer()

            Image(systemName: "keyboard")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Enable BitKeyboard")
                .font(.title)
                .fontWeight(.bold)

            Text("Go to Settings > General > Keyboard > Keyboards and add BitKeyboard to get started.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .xlarge)

            Button("Open Settings") {
                permissionService.openSettings()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
    }
}

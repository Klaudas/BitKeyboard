//
//  PermissionService.swift
//  BitKeyboard
//
//  Created by klaudas on 04/04/2026.
//

import UIKit
import Combine

final class PermissionService: ObservableObject {

    @Published private(set) var isKeyboardFullyEnabled = false

    private let extensionBundleID = XCConfig.extensionBundleId
    init() {
        refresh()
    }

    func refresh() {
        let keyboards = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] ?? []
        isKeyboardFullyEnabled = keyboards.contains(extensionBundleID) && hasFullAccess()
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func hasFullAccess() -> Bool {
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: XCConfig.appGroupId
        )
        return containerURL != nil
    }
}

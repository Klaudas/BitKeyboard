//
//  KeyboardViewController.swift
//  BitKeyboardExtension
//
//  Created by klaudas on 03/04/2026.
//

import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    nonisolated private let transportData: TransportDataService = {
        let mapper = TransportSecureMapper()
        return TransportDataService(mapper: mapper)
    }()

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let inputView else { return }
        let height = inputView.heightAnchor.constraint(equalToConstant: 260)
        height.priority = .required
        height.isActive = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let keyboardView = KeyboardView(
            onSymbolTap: { [weak self] name in self?.handleKeyTap(.symbols, name: name) },
            onDelete: { [weak self] in self?.handleDelete() },
            onUtilityTap: { [weak self] type in self?.handleKeyTap(.utilitySymbols, name: type.rawValue) }
        )

        view.layer.cornerRadius = 0
        view.clipsToBounds = true
        inputView?.layer.cornerRadius = 0
        inputView?.clipsToBounds = true

        let hostingController = UIHostingController(rootView: keyboardView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Key Handlers

    private func handleKeyTap(_ bundle: FilePath.Bundles, name: String) {
        Task.detached { [weak self] in
            try? self?.transportData.sendSymbol(bundle, name: name)
        }
    }

    private func handleDelete() {
        Task.detached { [weak self] in
            self?.transportData.post(.delete)
        }
    }

}
 

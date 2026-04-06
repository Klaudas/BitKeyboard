//
//  ContentView.swift
//  BitKeyboard
//
//  Created by klaudas on 03/04/2026.
//

import SwiftUI
import UIKit

struct ContentView: View {

    private let transportData = TransportDataService(mapper: TransportSecureMapper())

    @State private var images: [UIImage] = []
    @State private var selection = NSRange(location: NSNotFound, length: 0)

    var body: some View {
        TextView(
            images: images,
            selection: $selection,
            onDelete: { range in
                images.removeSubrange(range)
            }
        )
        .padding()
        .onAppear {
            transportData.observeSymbols { [self] in
                handleKeyTap()
            }
            transportData.observeDelete { [self] in
                handleDelete()
            }
        }
    }

    private func handleDelete() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        guard !images.isEmpty else { return }
        if selection.length > 0, selection.location != NSNotFound {
            let start = max(0, selection.location)
            let end = min(images.count, selection.location + selection.length)
            images.removeSubrange(start..<end)
        } else {
            _ = images.popLast()
        }
    }

    private func handleKeyTap() {
        Task.detached {
            do {
                let url = try await transportData.getSymbolURL()
                if let img = UIImage(contentsOfFile: url.path) {
                    await MainActor.run {
                        images.append(img)
                    }
                }
            } catch { }
        }
    }

}


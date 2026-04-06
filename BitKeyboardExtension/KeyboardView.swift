//
//  KeyboardView.swift
//  BitKeyboardExtension
//
//  Created by klaudas on 03/04/2026.
//

import SwiftUI

struct KeyboardView: View {
    
    var onSymbolTap: (String) -> Void
    var onDelete: () -> Void
    var onUtilityTap: (UtilitySymbolType) -> Void

    @State private var spaceLabel = "Bit Keyboard"
    @State private var deleteTimer: Timer?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: .small), count: 4)
    private let symbols: [(name: String, image: Image)] = FilePath.Bundles.symbols.fileURLs.map { url in
        let name = (url.lastPathComponent as NSString).deletingPathExtension
        guard let uiImage = UIImage(contentsOfFile: url.path)?.withRenderingMode(.alwaysTemplate) else { return (name, .blank) }
        return (name, Image(uiImage: uiImage))
    }

    var body: some View {
        VStack(spacing: .small) {
            symbolsView
            utilityView
        }
        .padding(.small)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    spaceLabel = "Space"
                }
            }
        }
    }

    @ViewBuilder
    private var symbolsView: some View {
        LazyVGrid(columns: columns, spacing: .small) {
            ForEach(Array(symbols.enumerated()), id: \.offset) { _, symbol in
                button(
                    symbol.image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color.primary)
                        .padding(.small)
                ) { onSymbolTap(symbol.name) }
            }
        }
    }
    
    @ViewBuilder
    private var utilityView: some View {
        HStack(spacing: .small) {
            button(Text(spaceLabel)) { onUtilityTap(.space) }.layoutPriority(1)
            button(Image.delete.padding(.horizontal), action: onDelete)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            guard deleteTimer == nil else { return }
                            onDelete()
                            deleteTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                                onDelete()
                                deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                                    onDelete()
                                }
                            }
                        }
                        .onEnded { _ in
                            deleteTimer?.invalidate()
                            deleteTimer = nil
                        }
                )
        }
    }
    
    @ViewBuilder
    private func button<Label: View>(_ label: Label, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            label
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(Color.primary)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadius).fill(Color(.systemGray4))
                )
                .contentTransition(.interpolate)
        }
        .buttonStyle(.plain)
    }

}

#Preview {
    KeyboardView(
        onSymbolTap: { _ in },
        onDelete: {},
        onUtilityTap: { _ in },

    )
}

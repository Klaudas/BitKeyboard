//
//  TextView.swift
//  BitKeyboard
//
//  Created by klaudas on 03/04/2026.
//

import SwiftUI
import UIKit

struct TextView: UIViewRepresentable {

    let images: [UIImage]
    @Binding var selection: NSRange
    let onDelete: (Range<Int>) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.backgroundColor = .systemGray5
        textView.keyboardDismissMode = .onDrag
        textView.textContainerInset = UIEdgeInsets(top: .small, left: .small, bottom: .small, right: .small)
        textView.font = UIFont.systemFont(ofSize: .xlarge)
        textView.becomeFirstResponder()
        textView.layer.cornerRadius = .cornerRadius
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.isUpdating = true
        defer { context.coordinator.isUpdating = false }

        let attributed = NSMutableAttributedString()

        for image in images {
            let symbolHeight: CGFloat = .xlarge
            let attachment = NSTextAttachment()
            attachment.image = image
            let aspect = image.size.width / image.size.height
            let width = symbolHeight * aspect
            attachment.bounds = CGRect(x: 0, y: -4, width: width, height: symbolHeight)
            attributed.append(NSAttributedString(attachment: attachment))
        }

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = .medium
        attributed.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: attributed.length))

        textView.attributedText = attributed
        textView.typingAttributes = [.font: UIFont.systemFont(ofSize: .xlarge), .paragraphStyle: paragraph]

        if attributed.length > 0 {
            let range = NSRange(location: attributed.length - 1, length: 1)
            textView.scrollRangeToVisible(range)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {

        @Binding var selection: NSRange
        var isUpdating = false

        init(selection: Binding<NSRange>) {
            _selection = selection
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isUpdating else { return }
            selection = textView.selectedRange
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            return false
        }
    }
}

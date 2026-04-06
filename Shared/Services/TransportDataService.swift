//
//  TransportDataService.swift
//  BitKeyboard
//
//  Created by klaudas on 03/04/2026.
//

import Foundation
import Combine

final class TransportDataService: ObservableObject {

    deinit {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
    }

    init(mapper: TransportSecureMapper) {
        self.mapper = mapper
    }

    private let mapper: TransportSecureMapper
    private let bundles = FilePath.Bundles.allCases
    private var handlers: [NotificationType: () -> Void] = [:]

    enum NotificationType: CaseIterable {
        case symbol
        case delete

        var notificationName: String {
            XCConfig.appGroupId + "." + String(describing: self)
        }
    }

    func sendSymbol(_ bundle: FilePath.Bundles, name: String) throws {
        let symbol = try getAsset(bundle, name: name)
        let (token, counter) = try mapper.seal(payload: symbol.id)
        try token.write(to: FilePath.url(for: .transportToken), options: .completeFileProtection)
        let counterData = withUnsafeBytes(of: counter) { Data($0) }
        try counterData.write(to: FilePath.url(for: .transportCounter), options: .completeFileProtection)
        post(.symbol)
    }

    func getSymbolURL() throws -> URL {
        let token = try Data(contentsOf: FilePath.url(for: .transportToken))
        let counterData = try Data(contentsOf: FilePath.url(for: .transportCounter))
        let counter = counterData.withUnsafeBytes { $0.load(as: UInt64.self) }
        let encryptedID = try mapper.open(token: token, counter: counter)
        let fileName = try getAsset(matching: encryptedID).fileName
        for bundle in bundles {
            let url = bundle.fileURL(for: fileName)
            if FileManager.default.fileExists(atPath: url.path) { return url }
        }
        throw TransportDataServiceError.symbolNotFound
    }

    private func getAsset(_ bundle: FilePath.Bundles, name: String) throws -> Symbol {
        let data = try Data(contentsOf: bundle.secureURL(for: name))
        return try JSONDecoder().decode(Symbol.self, from: data)
    }

    private func getAsset(matching encryptedID: Data) throws -> Symbol {
        for bundle in bundles {
            for url in bundle.fileURLs {
                let name = (url.lastPathComponent as NSString).deletingPathExtension
                guard let data = try? Data(contentsOf: bundle.secureURL(for: name)) else { continue }
                let symbol = try JSONDecoder().decode(Symbol.self, from: data)
                if symbol.id == encryptedID {
                    return symbol
                }
            }
        }
        throw TransportDataServiceError.symbolNotFound
    }
    
}

// MARK: - Post

extension TransportDataService {

    func post(_ type: NotificationType) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let name = CFNotificationName(type.notificationName as CFString)
        CFNotificationCenterPostNotification(center, name, nil, nil, true)
    }
    
}

// MARK: - Observe

extension TransportDataService {

    func observeSymbols(handler: @escaping () -> Void) {
        observe(.symbol, handler: handler)
    }

    func observeDelete(handler: @escaping () -> Void) {
        observe(.delete, handler: handler)
    }

    private func observe(_ type: NotificationType, handler: @escaping () -> Void) {
        handlers[type] = handler
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let observer = Unmanaged.passUnretained(self).toOpaque()
        CFNotificationCenterAddObserver(
            center,
            observer,
            { _, observer, name, _, _ in
                guard let observer, let name else { return }
                let nameString = name.rawValue as String
                guard let type = NotificationType.allCases.first(where: { $0.notificationName == nameString }) else { return }
                let service = Unmanaged<TransportDataService>.fromOpaque(observer).takeUnretainedValue()
                service.handlers[type]?()
            },
            type.notificationName as CFString,
            nil,
            .deliverImmediately
        )
    }
}

// MARK: - Errors

enum TransportDataServiceError: Error {
    case symbolNotFound
}


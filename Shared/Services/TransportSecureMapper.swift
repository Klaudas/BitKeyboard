//
//  TransportSecureMapper.swift
//  BitKeyboard
//
//  Created by klaudas on 03/04/2026.
//

import Foundation
import CryptoKit

final class TransportSecureMapper {

    init(key: SymmetricKey = getOrCreateDeviceSecret(), counterURL: URL = FilePath.url(for: .transportCounter)) {
        self.key = key
        self.counterURL = counterURL
    }

    private let key: SymmetricKey
    private let counterURL: URL

    // MARK: - Encrypt

    func seal(payload: Data) throws -> (token: Data, counter: UInt64) {
        let counter = try getCounter()
        let nextCounter = counter + 1

        let nonce = try AES.GCM.Nonce(data: getNonceData(from: nextCounter))
        let sealed = try AES.GCM.seal(payload, using: key, nonce: nonce)

        var token = sealed.ciphertext
        token.append(sealed.tag)

        try persistCounter(nextCounter)
        return (token, nextCounter)
    }

    // MARK: - Decrypt

    func open(token: Data, counter: UInt64) throws -> Data {
        let nonce = try AES.GCM.Nonce(data: getNonceData(from: counter))
        let tagSize = 16
        let ciphertext = token.prefix(token.count - tagSize)
        let tag = token.suffix(tagSize)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        var decrypted = try AES.GCM.open(sealedBox, using: key)
        defer { decrypted.resetBytes(in: decrypted.startIndex..<decrypted.endIndex) }
        return decrypted
    }

    // MARK: - Private

    private static func getOrCreateDeviceSecret() -> SymmetricKey {
        let url = FilePath.url(for: .deviceSecret)
        if let data = try? Data(contentsOf: url) {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        try? keyData.write(to: url, options: .completeFileProtection)
        return key
    }

    private func getCounter() throws -> UInt64 {
        guard FileManager.default.fileExists(atPath: counterURL.path) else { return 0 }
        let data = try Data(contentsOf: counterURL)
        return data.withUnsafeBytes { $0.load(as: UInt64.self) }
    }

    private func persistCounter(_ counter: UInt64) throws {
        let data = withUnsafeBytes(of: counter) { Data($0) }
        try data.write(to: counterURL, options: .completeFileProtection)
    }

    private func getNonceData(from counter: UInt64) -> Data {
        var counter = counter
        var data = Data(repeating: 0, count: 12)
        data.replaceSubrange(0..<8, with: Data(bytes: &counter, count: 8))
        return data
    }

}


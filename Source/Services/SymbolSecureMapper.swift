//
//  SymbolSecureMapper.swift
//  BitKeyboard
//
//  Created by klaudas on 03/04/2026.
//

import Foundation
import CryptoKit
import Combine

final class SymbolSecureMapper: ObservableObject {

    private let privateKey = try! SecureEnclave.P256.KeyAgreement.PrivateKey()
    private let bundles = FilePath.Bundles.allCases

    func generateSealedSymbolIDs() throws {
        cleanup()

        for bundle in bundles {
            for url in bundle.fileURLs {
                let name = (url.lastPathComponent as NSString).deletingPathExtension
                try sealAndWrite(fileName: url.lastPathComponent, to: bundle.secureURL(for: name))
            }
        }
    }

    private func cleanup() {
        for bundle in bundles {
            for url in bundle.fileURLs {
                let name = (url.lastPathComponent as NSString).deletingPathExtension
                try? FileManager.default.removeItem(at: bundle.secureURL(for: name))
            }
        }
    }

    private func sealAndWrite(fileName: String, to url: URL) throws {
        let sealedID = try seal(UUID().uuidString)
        let symbol = Symbol(id: sealedID, fileName: fileName)
        let encoded = try JSONEncoder().encode(symbol)
        try encoded.write(to: url, options: .completeFileProtection)
    }

    private func seal(_ id: String) throws -> Data {
        let data = Data(id.utf8)
        let ephemeralKey = P256.KeyAgreement.PrivateKey()
        let sharedSecret = try ephemeralKey.sharedSecretFromKeyAgreement(with: privateKey.publicKey)
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )
        let sealed = try AES.GCM.seal(data, using: symmetricKey)
        guard let combined = sealed.combined else {
            throw SymbolSecureMapperError.sealingFailed
        }
        return ephemeralKey.publicKey.x963Representation + combined
    }

}

// MARK: - Errors

enum SymbolSecureMapperError: Error {
    case sealingFailed
}

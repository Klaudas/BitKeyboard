//
//  TransportSecureMapperTests.swift
//  UnitTests
//
//  Created by klaudas on 03/04/2026.
//

import Testing
import Foundation
import CryptoKit
@testable import BitKeyboard

struct TransportSecureMapperTests {

    private func sy() -> TransportSecureMapper {
        let counterURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return TransportSecureMapper(key: SymmetricKey(size: .bits256), counterURL: counterURL)
    }

    @Test func testSealAndOpenRoundTrip() throws {
        let sut = makeSUT()
        let payload = Data("test-payload".utf8)

        let (token, counter) = try sut.seal(payload: payload)
        let result = try sut.open(token: token, counter: counter)

        #expect(result == payload)
    }

    @Test func testSealedTokenIsNotPlaintext() throws {
        let sut = makeSUT()
        let payload = Data("secret-symbol-id".utf8)

        let (token, _) = try sut.seal(payload: payload)

        // Token must not contain the original payload bytes
        let payloadRange = token.range(of: payload)
        #expect(payloadRange == nil, "Sealed token should not contain plaintext payload")

        // Token must not be valid UTF-8 readable text
        let asString = String(data: token, encoding: .utf8)
        #expect(asString == nil || asString != String(data: payload, encoding: .utf8))
    }

    @Test func testSealProducesPolymorphicTokens() throws {
        let sut = makeSUT()
        let payload = Data("same-data".utf8)

        let (token1, _) = try sut.seal(payload: payload)
        let (token2, _) = try sut.seal(payload: payload)

        #expect(token1 != token2)
    }

    @Test func testSealIncrementsCounterSequentially() throws {
        let sut = makeSUT()
        let payload = Data("counter-test".utf8)

        let (_, counter1) = try sut.seal(payload: payload)
        let (_, counter2) = try sut.seal(payload: payload)
        let (_, counter3) = try sut.seal(payload: payload)

        #expect(counter1 == 1)
        #expect(counter2 == 2)
        #expect(counter3 == 3)
    }

    @Test func testWrongCounterFailsDecryption() throws {
        let sut = makeSUT()

        let (token, counter) = try sut.seal(payload: Data("secret".utf8))

        #expect(throws: (any Error).self) {
            _ = try sut.open(token: token, counter: counter + 1)
        }
    }

    @Test func testWrongKeyFailsDecryption() throws {
        let counterURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sut1 = TransportSecureMapper(key: SymmetricKey(size: .bits256), counterURL: counterURL)
        let sut2 = TransportSecureMapper(key: SymmetricKey(size: .bits256), counterURL: counterURL)

        let (token, counter) = try sut1.seal(payload: Data("secret".utf8))

        #expect(throws: (any Error).self) {
            _ = try sut2.open(token: token, counter: counter)
        }
    }

    @Test func testTamperedTokenFailsDecryption() throws {
        let sut = makeSUT()

        var (token, counter) = try sut.seal(payload: Data("tamper-test".utf8))
        token[token.startIndex] ^= 0xFF

        #expect(throws: (any Error).self) {
            _ = try sut.open(token: token, counter: counter)
        }
    }

    @Test func testSealAndOpenMultiplePayloadsRoundTrip() throws {
        let sut = makeSUT()

        for i in 0..<12 {
            let payload = Data("payload-\(i)".utf8)
            let (token, counter) = try sut.seal(payload: payload)
            let result = try sut.open(token: token, counter: counter)
            #expect(result == payload)
        }
    }
}

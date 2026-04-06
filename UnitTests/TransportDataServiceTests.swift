//
//  TransportDataServiceTests.swift
//  UnitTests
//
//  Created by klaudas on 04/04/2026.
//

import Testing
import Foundation
import CryptoKit
@testable import BitKeyboard

@Suite(.serialized)
@MainActor
struct TransportDataServiceTests {

    private func makeSUT() -> (service: TransportDataService, mapper: TransportSecureMapper) {
        let counterURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let mapper = TransportSecureMapper(key: SymmetricKey(size: .bits256), counterURL: counterURL)
        let service = TransportDataService(mapper: mapper)
        return (service, mapper)
    }

    // MARK: - Send & Receive Round-Trip

    @Test func testSendSymbolWritesTokenAndCounter() throws {
        let (service, _) = makeSUT()

        try service.sendSymbol(.symbols, name: "0")

        let tokenData = try Data(contentsOf: FilePath.url(for: .transportToken))
        let counterData = try Data(contentsOf: FilePath.url(for: .transportCounter))

        #expect(!tokenData.isEmpty)
        #expect(!counterData.isEmpty)
    }

    @Test func testSendAndReceiveSymbolRoundTrip() throws {
        let (service, _) = makeSUT()

        try service.sendSymbol(.symbols, name: "0")
        let url = try service.getSymbolURL()

        #expect(url.lastPathComponent == "0.png")
    }

    @Test func testSendMultipleSymbolsResolvesCorrectly() throws {
        let (service, _) = makeSUT()

        let names = ["0", "1", "2", "3"]
        for name in names {
            try service.sendSymbol(.symbols, name: name)
            let url = try service.getSymbolURL()
            #expect(url.lastPathComponent == "\(name).png")
        }
    }

    // MARK: - Utility Symbols

    @Test func testSendSpaceUtilitySymbolRoundTrip() throws {
        let (service, _) = makeSUT()

        try service.sendSymbol(.utilitySymbols, name: UtilitySymbolType.space.rawValue)
        let url = try service.getSymbolURL()

        #expect(url.lastPathComponent == "space.png")
    }

    // MARK: - Polymorphic Tokens

    @Test func testSameSymbolProducesDifferentTokens() throws {
        let (service, _) = makeSUT()

        try service.sendSymbol(.symbols, name: "0")
        let token1 = try Data(contentsOf: FilePath.url(for: .transportToken))

        try service.sendSymbol(.symbols, name: "0")
        let token2 = try Data(contentsOf: FilePath.url(for: .transportToken))

        #expect(token1 != token2)
    }

    // MARK: - Security: Not Plaintext

    @Test func testTransportTokenIsNotPlaintext() throws {
        let (service, _) = makeSUT()

        try service.sendSymbol(.symbols, name: "0")

        let token = try Data(contentsOf: FilePath.url(for: .transportToken))

        // Token should not be decodable as a Symbol
        let decoded = try? JSONDecoder().decode(Symbol.self, from: token)
        #expect(decoded == nil, "Transport token should not be a plaintext Symbol")

        // Token should not contain the filename in readable form
        let filename = Data("0.png".utf8)
        #expect(token.range(of: filename) == nil, "Transport token should not contain plaintext filename")
    }

    // MARK: - Error Cases

    @Test func testGetSymbolURLWithoutSendingThrows() throws {
        let (service, _) = makeSUT()

        // Clear any existing token/counter files
        try? FileManager.default.removeItem(at: FilePath.url(for: .transportToken))
        try? FileManager.default.removeItem(at: FilePath.url(for: .transportCounter))

        #expect(throws: (any Error).self) {
            _ = try service.getSymbolURL()
        }
    }

    @Test func testSendInvalidSymbolNameThrows() throws {
        let (service, _) = makeSUT()

        #expect(throws: (any Error).self) {
            try service.sendSymbol(.symbols, name: "nonexistent")
        }
    }

}

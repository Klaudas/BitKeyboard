//
//  SymbolTests.swift
//  UnitTests
//
//  Created by klaudas on 04/04/2026.
//

import Testing
import Foundation
@testable import BitKeyboard

@MainActor
struct SymbolTests {

    // MARK: - Symbol Model

    @Test func testSymbolEncodeDecodeRoundTrip() throws {
        let original = Symbol(id: Data("test-id".utf8), fileName: "0.png")

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Symbol.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.fileName == original.fileName)
    }

    @Test func testSymbolPreservesArbitraryIdData() throws {
        let randomID = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let symbol = Symbol(id: randomID, fileName: "5.png")

        let encoded = try JSONEncoder().encode(symbol)
        let decoded = try JSONDecoder().decode(Symbol.self, from: encoded)

        #expect(decoded.id == randomID)
    }

    @Test func testSymbolDecodingFailsWithInvalidJSON() throws {
        let invalidJSON = Data("not json".utf8)

        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(Symbol.self, from: invalidJSON)
        }
    }

    // MARK: - UtilitySymbolType

    @Test func testUtilitySymbolTypeSpaceHasExpectedRawValue() {
        #expect(UtilitySymbolType.space.rawValue == "space")
    }

    @Test func testUtilitySymbolTypeInitFromRawValue() {
        let type = UtilitySymbolType(rawValue: "space")
        #expect(type == .space)
    }

    @Test func testUtilitySymbolTypeInvalidRawValueReturnsNil() {
        let type = UtilitySymbolType(rawValue: "invalid")
        #expect(type == nil)
    }

}

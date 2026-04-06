//
//  FilePathTests.swift
//  UnitTests
//
//  Created by klaudas on 04/04/2026.
//

import Testing
import Foundation
@testable import BitKeyboard

struct FilePathTests {

    @Test func testRawValues() {
        #expect(FilePath.Key.deviceSecret.rawValue == "deviceSecret")
        #expect(FilePath.Key.transportToken.rawValue == "transportToken")
        #expect(FilePath.Key.transportCounter.rawValue == "transportCounter")
        #expect(FilePath.Key.secure(.symbols, "5").rawValue == "symbols.5")
        #expect(FilePath.Key.secure(.utilitySymbols, "space").rawValue == "utilitySymbols.space")
    }

    @Test func testURLConstruction() {
        let deviceSecret = FilePath.url(for: .deviceSecret)
        let transportToken = FilePath.url(for: .transportToken)
        let transportCounter = FilePath.url(for: .transportCounter)
        let secure = FilePath.url(for: .secure(.symbols, "3"))

        #expect(deviceSecret.lastPathComponent == "deviceSecret")
        #expect(transportToken.lastPathComponent == "transportToken")
        #expect(transportCounter.lastPathComponent == "transportCounter")
        #expect(secure.lastPathComponent == "symbols.3")

        #expect(Set([deviceSecret, transportToken, transportCounter, secure]).count == 4)
    }

    @Test func testBundles() {
        #expect(FilePath.Bundles.allCases.count == 2)
        #expect(FilePath.Bundles.allCases.contains(.symbols))
        #expect(FilePath.Bundles.allCases.contains(.utilitySymbols))
        #expect(!FilePath.Bundles.symbols.fileURLs.isEmpty)
        #expect(FilePath.Bundles.symbols.fileURL(for: "0.png").lastPathComponent == "0.png")
    }

}

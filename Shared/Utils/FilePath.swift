//
//  FilePath.swift
//  BitKeyboard
//
//  Created by klaudas on 03/04/2026.
//

import Foundation

nonisolated enum FilePath {
    
    enum Bundles: String, CaseIterable {
        case symbols
        case utilitySymbols
        
        var bundleURL: URL {
            Bundle.main.url(forResource: rawValue.prefix(1).uppercased() + rawValue.dropFirst(), withExtension: "bundle")!
        }

        var fileURLs: [URL] {
            Self.cache[self, default: []]
        }

        private static let cache: [Bundles: [URL]] = {
            var result: [Bundles: [URL]] = [:]
            for bundle in Bundles.allCases {
                let contents = try? FileManager.default.contentsOfDirectory(at: bundle.bundleURL, includingPropertiesForKeys: nil)
                result[bundle] = (contents ?? []).sorted { $0.lastPathComponent < $1.lastPathComponent }
            }
            return result
        }()

        func fileURL(for fileName: String) -> URL {
            bundleURL.appendingPathComponent(fileName)
        }

        func secureURL(for name: String) -> URL {
            FilePath.url(for: .secure(self, name))
        }
    }

    enum Key {
        case deviceSecret
        case transportToken
        case transportCounter
        case secure(Bundles, String)

        var rawValue: String {
            switch self {
            case .secure(let bundle, let name):
                [bundle.rawValue, name].joined(separator: ".")
            default:
                String(describing: self)
            }
        }
    }

    static func url(for key: Key) -> URL {
        containerURL.appendingPathComponent(key.rawValue)
    }

    private static var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: XCConfig.appGroupId)!
    }

}

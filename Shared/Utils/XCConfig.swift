import Foundation

nonisolated final class XCConfig {
    
//    init() {
//        Self.checkIfValuesExists()
//    }

    // MARK: - Keys

    enum ConfigKeys: String, CaseIterable {
        case bundleId = "PRODUCT_BUNDLE_IDENTIFIER"
        case extensionBundleId = "EXTENSION_BUNDLE_IDENTIFIER"
        case appGroupId = "APP_GROUP_ID"

    }

    private static let shared = XCConfig()

    static func checkIfValuesExists() {
        ConfigKeys.allCases.forEach { shared.value($0) }
    }

    @discardableResult
    private func value(_ key: ConfigKeys) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String else {
            fatalError("\(key.rawValue) doesn't exist or is not included in Info.plist")
        }
        return value
    }

    // MARK: - Properties

    static var bundleId: String { shared.value(.bundleId) }
    static var extensionBundleId: String { shared.value(.extensionBundleId) }
    static var appGroupId: String { shared.value(.appGroupId) }


}

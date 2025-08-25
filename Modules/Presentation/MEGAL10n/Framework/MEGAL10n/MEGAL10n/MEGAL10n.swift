import Foundation

final class MEGAL10nBundleClass {}

extension Bundle {
    static let MEGAL10nBundle = Bundle(for: MEGAL10nBundleClass.self)
}

public extension Strings {
    static func localized(_ key: String, comment: String) -> String {
        Bundle.MEGAL10nBundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}

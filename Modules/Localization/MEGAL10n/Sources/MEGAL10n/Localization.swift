import Foundation

public extension Strings {
    static func localized(_ key: String, comment: String) -> String {
        Bundle.module.localizedString(forKey: key, value: key, table: "Localizable")
    }
}

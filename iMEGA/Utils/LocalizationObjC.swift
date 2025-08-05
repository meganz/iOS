import MEGAL10n

@objc public class LocalizationObjC: NSObject {
    @objc public static func localizedValue(forKey key: String, comment: String) -> String {
        Strings.localized(key, comment: comment)
    }
}

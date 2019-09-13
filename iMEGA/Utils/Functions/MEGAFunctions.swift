
import Foundation

func AMLocalizedString(_ key: String, _ comment: String? = nil) -> String {
    return LocalizationSystem.sharedLocal().localizedString(forKey: key, value: comment)
}

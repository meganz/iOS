
import Foundation

extension String {
    func localized(comment: String = "") -> String {
        return LocalizationSystem.sharedLocal()!.localizedString(forKey: self, value: comment)
    }
}

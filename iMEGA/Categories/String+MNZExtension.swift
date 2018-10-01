
import Foundation

extension String {
    func localized() -> String {
        return localized(withComment: nil)
    }
    
    func localized(withComment comment: String!) -> String {
        return LocalizationSystem.sharedLocal()?.localizedString(forKey: self, value: comment) ?? self
    }
}

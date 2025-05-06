import Foundation
import MEGADomain
import MEGAPreference

@objc protocol RecentsPreferenceProtocol: AnyObject {
    func recentsPreferenceChanged()
}

@objc final class RecentsPreferenceManager: NSObject {
    @PreferenceWrapper(key: PreferenceKeyEntity.showRecents, defaultValue: true, useCase: PreferenceUseCase.default)
    private static var recentsPreference: Bool
    @objc static var delegate: (any RecentsPreferenceProtocol)?
    
    @objc static func setShowRecents(_ showRecents: Bool) {
        recentsPreference = showRecents
        delegate?.recentsPreferenceChanged()
    }
    
    @objc static func showRecents() -> Bool {
        return recentsPreference
    }
}

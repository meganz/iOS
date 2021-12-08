import Foundation

@objc protocol RecentsPreferenceProtocol: AnyObject {
    func recentsPreferenceChanged()
}

@objc final class RecentsPreferenceManager: NSObject {
    @PreferenceWrapper(key: .showRecents, defaultValue: true)
    private static var recentsPreference: Bool
    @objc static var delegate: RecentsPreferenceProtocol?
    
    @objc static func setShowRecents(_ showRecents: Bool) {
        recentsPreference = showRecents
        delegate?.recentsPreferenceChanged()
    }
    
    @objc static func showRecents() -> Bool {
        return recentsPreference
    }
}

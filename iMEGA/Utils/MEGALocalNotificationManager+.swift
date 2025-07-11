import MEGAL10n

@objc extension MEGALocalNotificationManager {    
    func generalCountFiles(_ size: Int) -> String {
        Strings.Localizable.General.Format.Count.file(size)
    }
    
    func notFound() -> String {
        Strings.Localizable.notFound
    }
    
    func pinnedLocation() -> String {
        Strings.Localizable.pinnedLocation
    }
    
    func edited() -> String {
        Strings.Localizable.edited
    }
    
    func missedCall() -> String {
        Strings.Localizable.missedCall
    }
    
    func stringFrom(timeIntermval: TimeInterval) -> String {
        timeIntermval.timeString
    }
}

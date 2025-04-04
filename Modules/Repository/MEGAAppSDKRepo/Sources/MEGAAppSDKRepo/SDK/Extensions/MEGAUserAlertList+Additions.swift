import MEGASdk

@objc public extension MEGAUserAlertList {
    var relevantUserAlertsArray: [MEGAUserAlert] {
        userAlerts(where: { $0.isRelevant }).reversed()
    }
    
    var relevantUnseenCount: UInt {
        UInt(userAlerts(where: { $0.isRelevant && !$0.isSeen }).count)
    }
    
    private func userAlerts(where isIncluded: (MEGAUserAlert) -> Bool) -> [MEGAUserAlert] {
        (0..<size)
            .compactMap {
                guard let alert = usertAlert(at: $0), isIncluded(alert) else { return nil }
                
                return alert
            }
    }
}

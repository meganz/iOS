@objc extension MEGAAchievementsDetails {
    func isAwardPermanentAt(index: UInt) -> Bool {
        guard let expirationTs = awardExpiration(at: index)?.timeIntervalSince1970 else { return false }
        return expirationTs == 0
    }
}

public struct RaiseHandNewFeatureBadgeKeyEntity {
    // This key is used in iOS to save raise hand feature badge state for user account. Don't change it.
    public static let key = "iOsRhFb"
    
    private init() { }
}

public struct RaiseHandNewFeatureBadgeEntity: Codable, Sendable {
    public let presentedCount: Int
    
    public init(presentedCount: Int) {
        self.presentedCount = presentedCount
    }
}

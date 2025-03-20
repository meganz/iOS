public struct NoteToSelfNewFeatureBadgeKeyEntity {
    // This key is used in iOS to save note to self chat feature badge state for user account. Don't change it.
    public static let key = "iN2Sb"
    
    private init() { }
}

public struct NoteToSelfNewFeatureBadgeEntity: Codable, Sendable {
    public let presentedCount: Int
    
    public init(presentedCount: Int) {
        self.presentedCount = presentedCount
    }
}

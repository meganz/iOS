import MEGASdk

public final class MockMEGAAchievementDetails: MEGAAchievementsDetails {
    private let ahievementAwardsCount: UInt

    public init(ahievementAwardsCount: UInt) {
        self.ahievementAwardsCount = ahievementAwardsCount
    }

    override public var awardsCount: UInt {
        return ahievementAwardsCount
    }
}

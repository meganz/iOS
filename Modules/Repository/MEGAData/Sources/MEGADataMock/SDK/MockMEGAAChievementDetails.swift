import MEGASdk

public final class MockMEGAAchievementDetails: MEGAAchievementsDetails {
    private let achievementAwardsCount: UInt
    private let classStorageTransformation: ((Int) -> Int64)?
    private let classTransfersTransformation: ((Int) -> Int64)?
    private let classExpiresTransformation: ((Int) -> Int)?

    public init(
        achievementAwardsCount: UInt,
        classStorage: ((Int) -> Int64)? = nil,
        classTransfers: ((Int) -> Int64)? = nil,
        classExpires: ((Int) -> Int)? = nil
    ) {
        self.achievementAwardsCount = achievementAwardsCount
        self.classStorageTransformation = classStorage
        self.classTransfersTransformation = classTransfers
        self.classExpiresTransformation = classExpires
    }

    override public var awardsCount: UInt {
        return achievementAwardsCount
    }
    
    override public func classStorage(forClassId id: Int) -> Int64 {
        classStorageTransformation?(id) ?? -1
    }
    
    override public func classTransfer(forClassId id: Int) -> Int64 {
        classTransfersTransformation?(id) ?? -1
    }
    
    override public func classExpire(forClassId id: Int) -> Int {
        classExpiresTransformation?(id) ?? -1
    }
}

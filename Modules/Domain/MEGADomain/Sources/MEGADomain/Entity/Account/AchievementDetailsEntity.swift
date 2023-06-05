import Foundation

public struct AchievementDetailsEntity: Sendable {
    public let baseStorage: Int64
    public let currentStorage: Int64
    public let currentTransfer: Int64
    public let currentStorageReferrals: Int64
    public let currentTransferReferrals: Int64
    public let awardsCount: UInt
    public let rewardsCount: Int

    public let classStorages: [AchivementDetailsClassStorage]
    public let classTransfers: [AchivementDetailsClassTransfer]
    public let classExpires: [AchivementDetailsClassExpire]
    public let awardClasses: [Int]
    public let awardIds: [Int]
    public let awardTimestamps: [Date]
    public let awardExpirations: [Date]
    public let awardEmails: [String]
    public let rewardAwards: [Int]
    public let rewardStorages: [Int64]
    public let rewardTransfers: [Int64]
    public let rewardStoragesByAwardId: [Int64]
    public let rewardTransfersByAwardId: [Int64]
    public let rewardExpireByAwardId: [Int]
    
    public init(
        baseStorage: Int64,
        currentStorage: Int64,
        currentTransfer: Int64,
        currentStorageReferrals: Int64,
        currentTransferReferrals: Int64,
        awardsCount: UInt,
        rewardsCount: Int,
        classStorages: [AchivementDetailsClassStorage],
        classTransfers: [AchivementDetailsClassTransfer],
        classExpires: [AchivementDetailsClassExpire],
        awardClasses: [Int],
        awardIds: [Int],
        awardTimestamps: [Date],
        awardExpirations: [Date],
        awardEmails: [String],
        rewardAwards: [Int],
        rewardStorages: [Int64],
        rewardTransfers: [Int64],
        rewardStoragesByAwardId: [Int64],
        rewardTransfersByAwardId: [Int64],
        rewardExpireByAwardId: [Int]
    ) {
        self.baseStorage = baseStorage
        self.currentStorage = currentStorage
        self.currentTransfer = currentTransfer
        self.currentStorageReferrals = currentStorageReferrals
        self.currentTransferReferrals = currentTransferReferrals
        self.awardsCount = awardsCount
        self.rewardsCount = rewardsCount
        self.classStorages = classStorages
        self.classTransfers = classTransfers
        self.classExpires = classExpires
        self.awardClasses = awardClasses
        self.awardIds = awardIds
        self.awardTimestamps = awardTimestamps
        self.awardExpirations = awardExpirations
        self.awardEmails = awardEmails
        self.rewardAwards = rewardAwards
        self.rewardStorages = rewardStorages
        self.rewardTransfers = rewardTransfers
        self.rewardStoragesByAwardId = rewardStoragesByAwardId
        self.rewardTransfersByAwardId = rewardTransfersByAwardId
        self.rewardExpireByAwardId = rewardExpireByAwardId
    }

    public func classStorage(for type: AchievementTypeEntity) -> Int64 {
        classStorages.first(where: {$0.achievementType == type})?.storage ?? 0
    }

    public func classTransfer(for type: AchievementTypeEntity) -> Int64 {
        classTransfers.first(where: {$0.achievementType == type})?.transfer ?? 0
    }

    public func classExpire(for type: AchievementTypeEntity) -> Int {
        classExpires.first(where: {$0.achievementType == type})?.expire ?? 0
    }
}

public struct AchivementDetailsClassStorage: Sendable {
    public let achievementType: AchievementTypeEntity
    public let storage: Int64

    public init(achievementType: AchievementTypeEntity, storage: Int64) {
        self.achievementType = achievementType
        self.storage = storage
    }
}

public struct AchivementDetailsClassTransfer: Sendable {
    public let achievementType: AchievementTypeEntity
    public let transfer: Int64

    public init(achievementType: AchievementTypeEntity, transfer: Int64) {
        self.achievementType = achievementType
        self.transfer = transfer
    }
}

public struct AchivementDetailsClassExpire: Sendable {
    public let achievementType: AchievementTypeEntity
    public let expire: Int

    public init(achievementType: AchievementTypeEntity, expire: Int) {
        self.achievementType = achievementType
        self.expire = expire
    }
}

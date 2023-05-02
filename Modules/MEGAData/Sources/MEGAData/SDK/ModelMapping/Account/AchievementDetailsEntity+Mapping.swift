import MEGASdk
import MEGADomain

extension MEGAAchievementsDetails {
    public func toAchievementDetailsEntity() -> AchievementDetailsEntity {
        let totalCount = max(0, awardsCount-1)
        let awards: [UInt] = (0...totalCount).map { $0 }
        let classes = (0...totalCount).map { awardClass(at: $0) }
        var awardEmailsArray: [String] = []
        
        classes.forEach {
            guard let awardEmails = awardEmails(at: UInt($0)), awardEmails.size > 0 else { return }
            awardEmailsArray.append(awardEmails.string(at: 0))
        }

        return AchievementDetailsEntity(
            baseStorage: baseStorage,
            currentStorage: currentStorage,
            currentTransfer: currentTransfer,
            currentStorageReferrals: currentStorageReferrals,
            currentTransferReferrals: currentTransferReferrals,
            awardsCount: awardsCount,
            rewardsCount: rewardsCount,
            classStorages: AchievementTypeEntity.allCases.map {
                AchivementDetailsClassStorage(
                    achievementType: $0,
                    storage: classStorage(forClassId: $0.rawValue)
                )
            },
            classTransfers: AchievementTypeEntity.allCases.map {
                AchivementDetailsClassTransfer(
                    achievementType: $0,
                    transfer: classTransfer(forClassId: $0.rawValue)
                )
            },
            classExpires: AchievementTypeEntity.allCases.map {
                AchivementDetailsClassExpire(
                    achievementType: $0,
                    expire: classExpire(forClassId: $0.rawValue)
                )
            },
            awardClasses: awards.map { awardClass(at: $0) },
            awardIds: awards.map { awardId(at: $0) },
            awardTimestamps: awards.map { awardTimestamp(at: $0) },
            awardExpirations: awards.map { awardExpiration(at: $0) },
            awardEmails: awardEmailsArray,
            rewardAwards: awards.map { rewardAwardId(at: $0) },
            rewardStorages: awards.map { rewardStorage(at: $0) },
            rewardTransfers: awards.map { rewardTransfer(at: $0) },
            rewardStoragesByAwardId: awards.map { rewardStorage(byAwardId: Int($0)) },
            rewardTransfersByAwardId: awards.map { rewardTransfer(byAwardId: Int($0)) },
            rewardExpireByAwardId: awards.map { rewardExpire(at: $0) }
        )
    }
}

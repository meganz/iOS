import MEGADomain
import MEGASdk

extension MEGAAchievementsDetails {
    public func toAchievementDetailsEntity() -> AchievementDetailsEntity {
        let totalCount = awardsCount == 0 ? 0 : awardsCount - 1
        
        let awards: [UInt] = totalCount > 0 ? (0...totalCount).map { $0 } : []
        let classes = totalCount > 0 ? (0...totalCount).map { awardClass(at: $0) } : []

        var awardEmailsArray: [String] = []
        classes.forEach {
            guard let awardEmails = awardEmails(at: UInt($0)),
                  awardEmails.size > 0,
                  let email = awardEmails.string(at: 0) else { return }
            awardEmailsArray.append(email)
        }

        return AchievementDetailsEntity(
            baseStorage: baseStorage,
            currentStorage: currentStorage,
            currentTransfer: currentTransfer,
            currentStorageReferrals: currentStorageReferrals,
            currentTransferReferrals: currentTransferReferrals,
            awardsCount: awardsCount,
            rewardsCount: rewardsCount,
            classStorages: AchievementTypeEntity.allCases.map { $0.toAchievementDetails(classStorage: classStorage(forClassId:)) },
            classTransfers: AchievementTypeEntity.allCases.map { $0.toAchievementDetails(classTransfer: classTransfer(forClassId:)) },
            classExpires: AchievementTypeEntity.allCases.map { $0.toAchievementDetails(classExpire: classExpire(forClassId:)) },
            awardClasses: awards.map { awardClass(at: $0) },
            awardIds: awards.map { awardId(at: $0) },
            awardTimestamps: awards.map { awardTimestamp(at: $0) ?? Date() },
            awardExpirations: awards.map { awardExpiration(at: $0) ?? Date() },
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

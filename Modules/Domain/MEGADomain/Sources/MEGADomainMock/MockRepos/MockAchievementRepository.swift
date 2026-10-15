import Foundation
import MEGADomain

public struct MockAchievementRepository: AchievementRepositoryProtocol {
    public static var newRepo: MockAchievementRepository {
        MockAchievementRepository()
    }
    
    let isAchievementsEnabled: Bool
    let storageResult: Measurement<UnitInformationStorage>?
    let achievementDetailsResult: AchievementDetailsEntity?
    let baseStorage: Int64
    
    public init(isAchievementsEnabled: Bool = true,
                storageResult: Measurement<UnitInformationStorage>? = nil,
                achievementDetailsResult: AchievementDetailsEntity? = nil,
                baseStorage: Int64 = 20
    ) {
        self.isAchievementsEnabled = isAchievementsEnabled
        self.storageResult = storageResult
        self.achievementDetailsResult = achievementDetailsResult
        self.baseStorage = baseStorage
    }
    
    public func checkIsAchievementsEnabled() -> Bool {
        isAchievementsEnabled
    }

    public func getAchievementStorage(by type: AchievementTypeEntity) async throws -> Measurement<UnitInformationStorage> {
        guard let storageResult = storageResult else { throw AchievementErrorEntity.generic }
        return storageResult
    }

    public func baseStorage() async throws -> Int64 {
        baseStorage
    }
    
    public func getAchievementDetails() async throws -> AchievementDetailsEntity {
        guard let achievementDetailsResult = achievementDetailsResult else { throw AchievementErrorEntity.generic }
        return achievementDetailsResult
    }
}

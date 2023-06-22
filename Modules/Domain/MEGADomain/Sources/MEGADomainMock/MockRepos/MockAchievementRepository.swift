import Foundation
import MEGADomain
import MEGAFoundation

public struct MockAchievementRepository: AchievementRepositoryProtocol {
    public static var newRepo: MockAchievementRepository {
        MockAchievementRepository()
    }
    
    let isAchievementsEnabled: Bool
    let storageResult: Measurement<UnitDataStorage>?
    let achievementDetailsResult: AchievementDetailsEntity?
    
    public init(isAchievementsEnabled: Bool = true,
                storageResult: Measurement<UnitDataStorage>? = nil,
                achievementDetailsResult: AchievementDetailsEntity? = nil
    ) {
        self.isAchievementsEnabled = isAchievementsEnabled
        self.storageResult = storageResult
        self.achievementDetailsResult = achievementDetailsResult
    }
    
    public func checkIsAchievementsEnabled() -> Bool {
        isAchievementsEnabled
    }

    public func getAchievementStorage(by type: AchievementTypeEntity) async throws -> Measurement<UnitDataStorage> {
        guard let storageResult = storageResult else { throw AchievementErrorEntity.generic }
        return storageResult
    }

    public func getAchievementDetails() async throws -> AchievementDetailsEntity {
        guard let achievementDetailsResult = achievementDetailsResult else { throw AchievementErrorEntity.generic }
        return achievementDetailsResult
    }
}

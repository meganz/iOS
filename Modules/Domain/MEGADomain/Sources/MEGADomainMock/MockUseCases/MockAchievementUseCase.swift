import Foundation
import MEGADomain

public struct MockAchievementUseCase: AchievementUseCaseProtocol {
    let result: Measurement<UnitInformationStorage>?
    let achievementDetailsResult: AchievementDetailsEntity?
    let isAchievementsEnabled: Bool
    let baseStorage: Int64
    
    public init(result: Measurement<UnitInformationStorage>? = nil,
                achievementDetailsResult: AchievementDetailsEntity? = nil,
                isAchievementsEnabled: Bool = true,
                baseStorage: Int64 = 20
    ) {
        self.result = result
        self.achievementDetailsResult = achievementDetailsResult
        self.isAchievementsEnabled = isAchievementsEnabled
        self.baseStorage = baseStorage
    }
    
    public func checkIsAchievementsEnabled() -> Bool { isAchievementsEnabled }

    public func getAchievementStorage(by type: AchievementTypeEntity) async throws -> Measurement<UnitInformationStorage> {
        guard let result = result else { throw AchievementErrorEntity.generic }
        guard checkIsAchievementsEnabled() else { throw AchievementErrorEntity.achievementsDisabled }
        return result
    }

    public func baseStorage() async throws -> Int64 {
        baseStorage
    }
    
    public func getAchievementDetails() async throws -> AchievementDetailsEntity {
        guard let achievementDetailsResult = achievementDetailsResult else { throw AchievementErrorEntity.generic }
        return achievementDetailsResult
    }
}

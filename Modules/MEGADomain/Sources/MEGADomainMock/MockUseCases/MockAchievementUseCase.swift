import MEGADomain
import MEGAFoundation
import Foundation

public struct MockAchievementUseCase: AchievementUseCaseProtocol {
    let result: Result<Measurement<UnitDataStorage>, AchievementErrorEntity>
    let isAchievementsEnabled: Bool
    
    public init(result: Result<Measurement<UnitDataStorage>, AchievementErrorEntity> = .failure(.generic),
                isAchievementsEnabled: Bool = true) {
        self.result = result
        self.isAchievementsEnabled = isAchievementsEnabled
    }
    
    public func checkIsAchievementsEnabled() -> Bool { isAchievementsEnabled }
    
    public func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void) {
        completion(result)
    }
}

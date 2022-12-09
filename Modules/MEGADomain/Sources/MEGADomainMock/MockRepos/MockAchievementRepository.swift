import MEGADomain
import MEGAFoundation
import Foundation

public struct MockAchievementRepository: AchievementRepositoryProtocol {
    public static var newRepo: MockAchievementRepository {
        MockAchievementRepository()
    }
    
    let isAchievementsEnabled: Bool
    let storageResult: Result<Measurement<UnitDataStorage>, AchievementErrorEntity>
    
    public init(isAchievementsEnabled: Bool = true,
                storageResult: Result<Measurement<UnitDataStorage>, AchievementErrorEntity> = .failure(.generic)) {
        self.isAchievementsEnabled = isAchievementsEnabled
        self.storageResult = storageResult
    }
    
    public func checkIsAchievementsEnabled() -> Bool {
        isAchievementsEnabled
    }
    
    public func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void) {
        completion(storageResult)
    }
}

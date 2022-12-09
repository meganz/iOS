import MEGAFoundation
import Foundation

public protocol AchievementRepositoryProtocol: RepositoryProtocol {
    func checkIsAchievementsEnabled() -> Bool
    func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void)
}

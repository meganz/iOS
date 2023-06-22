import Foundation
import MEGAFoundation

public protocol AchievementRepositoryProtocol: RepositoryProtocol {
    func checkIsAchievementsEnabled() -> Bool
    func getAchievementStorage(by type: AchievementTypeEntity) async throws -> Measurement<UnitDataStorage>
    func getAchievementDetails() async throws -> AchievementDetailsEntity
}

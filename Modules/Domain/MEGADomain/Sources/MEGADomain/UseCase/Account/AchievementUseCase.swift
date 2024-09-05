import Foundation
import MEGAFoundation

// MARK: - Use case protocol -
public protocol AchievementUseCaseProtocol: Sendable {
    func getAchievementStorage(by type: AchievementTypeEntity) async throws -> Measurement<UnitDataStorage>
    func baseStorage() async throws -> Int64
    func getAchievementDetails() async throws -> AchievementDetailsEntity
}

public struct AchievementUseCase<T: AchievementRepositoryProtocol>: AchievementUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }

    public func getAchievementStorage(by type: AchievementTypeEntity) async throws -> Measurement<UnitDataStorage> {
        guard repo.checkIsAchievementsEnabled() else { throw AchievementErrorEntity.achievementsDisabled }
        return try await repo.getAchievementStorage(by: type)
    }
    
    public func baseStorage() async throws -> Int64 {
        try await repo.baseStorage()
    }

    public func getAchievementDetails() async throws -> AchievementDetailsEntity {
        try await repo.getAchievementDetails()
    }
}

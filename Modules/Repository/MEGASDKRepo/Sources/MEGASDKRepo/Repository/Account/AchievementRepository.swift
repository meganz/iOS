import Foundation
import MEGADomain
import MEGAFoundation
import MEGASdk
import MEGASwift

public struct AchievementRepository: AchievementRepositoryProtocol {
    public static var newRepo: AchievementRepository {
        AchievementRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func checkIsAchievementsEnabled() -> Bool {
        sdk.isAchievementsEnabled
    }
    
    public func getAchievementStorage(by type: AchievementTypeEntity) async throws -> Measurement<UnitDataStorage> {
        let achievementDetails = try await getAchievementDetails()
        return Measurement<UnitDataStorage>.bytes(of: achievementDetails.classStorage(for: type))
    }

    public func getAchievementDetails() async throws -> AchievementDetailsEntity {
        try await withAsyncThrowingValue(in: { completion in
            sdk.getAccountAchievements(with: RequestDelegate(completion: { result in
                switch result {
                case .success(let request):
                    completion(.success(request.megaAchievementsDetails.toAchievementDetailsEntity()))
                case .failure:
                    completion(.failure(AchievementErrorEntity.generic))
                }
            }))
        })
    }
}

import Foundation
import MEGADomain
import MEGAFoundation
import MEGASdk

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
    
    public func getAchievementStorage(by type: AchievementTypeEntity, completion: @escaping (Result<Measurement<UnitDataStorage>, AchievementErrorEntity>) -> Void) {
        getAchievementDetails {
            completion(
                $0.map { achievementDetails in
                    .bytes(of: achievementDetails.classStorage(forClassId: type.rawValue))
                }
                .mapError { _ in
                    AchievementErrorEntity.generic
                }
            )
        }
    }
    
    private func getAchievementDetails(completion: @escaping (Result<MEGAAchievementsDetails, MEGAError>) -> Void) {
        sdk.getAccountAchievements(with: RequestDelegate { result in
            switch result {
            case .success(let request):
                completion(.success(request.megaAchievementsDetails))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}

import MEGADomain
import MEGASwift

public final class MockRubbishBinSettingsRepository: RubbishBinSettingsRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockRubbishBinSettingsRepository {
        MockRubbishBinSettingsRepository()
    }
    
    public private(set) var cleanRubbishBinCalled = false
    public private(set) var catchupWithSDKCalled = false
    public private(set) var setRubbishBinAutopurgePeriodCalled = false
    public private(set) var rubbishBinAutopurgePeriodDays = 0
    private let rubbishBinSettingsEntity: RubbishBinSettingsEntity
    
    public init(
        rubbishBinSettingsEntity: RubbishBinSettingsEntity = RubbishBinSettingsEntity(
            rubbishBinAutopurgePeriod: 14,
            rubbishBinCleaningSchedulerEnabled: true
        )
    ) {
        self.rubbishBinSettingsEntity = rubbishBinSettingsEntity
    }
    
    public func cleanRubbishBin() async throws {
        cleanRubbishBinCalled = true
    }
    
    public func catchupWithSDK() async throws {
        catchupWithSDKCalled = true
    }
    
    public func setRubbishBinAutopurgePeriod(in days: Int) async {
        setRubbishBinAutopurgePeriodCalled = true
        rubbishBinAutopurgePeriodDays = days
    }
    
    public func getRubbishBinAutopurgePeriod() async throws -> RubbishBinSettingsEntity {
        rubbishBinSettingsEntity
    }
}

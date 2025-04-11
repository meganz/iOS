import MEGADomain
import MEGASwift

public final class MockRubbishBinSettingsUseCase: RubbishBinSettingsUseCaseProtocol, @unchecked Sendable {
    
    public var cleanRubbishBinCalled = false
    public var catchupWithSDKCalled = false
    public var setRubbishBinAutopurgePeriod = false
    private let rubbishBinSettingsEntity: RubbishBinSettingsEntity
    
    public init(rubbishBinSettingsEntity: RubbishBinSettingsEntity = RubbishBinSettingsEntity(rubbishBinAutopurgePeriod: 14, rubbishBinCleaningSchedulerEnabled: true)) {
        self.rubbishBinSettingsEntity = rubbishBinSettingsEntity
    }
    
    public func cleanRubbishBin() async throws {
        cleanRubbishBinCalled = true
    }
    
    public func catchupWithSDK() async throws {
        catchupWithSDKCalled = true
    }
    
    public func setRubbishBinAutopurgePeriod(in days: Int) async {
        setRubbishBinAutopurgePeriod = true
    }
    
    public func getRubbishBinAutopurgePeriod() async throws -> RubbishBinSettingsEntity {
        rubbishBinSettingsEntity
    }
}

import MEGADomain
import MEGASwift

public final class MockRubbishBinSettingsRepository: RubbishBinSettingsRepositoryProtocol, @unchecked Sendable {
    public let onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>>
    
    public private(set) var cleanRubbishBinCalled = false
    public private(set) var catchupWithSDKCalled = false
    public private(set) var setRubbishBinAutopurgePeriodCalled = false
    public private(set) var rubbishBinAutopurgePeriodDays = 0
    
    public init(onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self.onRubbishBinSettinghsRequestFinish = onRubbishBinSettinghsRequestFinish
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
}

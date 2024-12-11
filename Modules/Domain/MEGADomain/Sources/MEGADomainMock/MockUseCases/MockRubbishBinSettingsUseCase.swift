import MEGADomain
import MEGASwift

public final class MockRubbishBinSettingsUseCase: RubbishBinSettingsUseCaseProtocol, @unchecked Sendable {
    public var onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>>
    public var cleanRubbishBinCalled = false
    public var catchupWithSDKCalled = false
    public var setRubbishBinAutopurgePeriod = false
    
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
        setRubbishBinAutopurgePeriod = true
    }
}

import MEGADomain
import MEGASwift

public final class MockRubbishBinSettingsUseCase: RubbishBinSettingsUseCaseProtocol, @unchecked Sendable {
    public var onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>>
    public var cleanRubbishBinCalled = false
    
    public init(onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self.onRubbishBinSettinghsRequestFinish = onRubbishBinSettinghsRequestFinish
    }
    
    public func cleanRubbishBin() {
        cleanRubbishBinCalled = true
    }
}

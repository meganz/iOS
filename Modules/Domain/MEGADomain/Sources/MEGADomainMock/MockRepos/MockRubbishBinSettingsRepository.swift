import MEGADomain
import MEGASwift

public struct MockRubbishBinSettingsRepository: RubbishBinSettingsRepositoryProtocol {
    public let onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>>
    
    public init(onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> = EmptyAsyncSequence().eraseToAnyAsyncSequence()) {
        self.onRubbishBinSettinghsRequestFinish = onRubbishBinSettinghsRequestFinish
    }
}

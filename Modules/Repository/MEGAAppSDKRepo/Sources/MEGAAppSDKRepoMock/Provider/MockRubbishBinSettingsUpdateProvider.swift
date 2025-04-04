import MEGAAppSDKRepo
import MEGADomain
import MEGASwift

public struct MockRubbishBinSettingsUpdateProvider: RubbishBinSettingsUpdateProviderProtocol, Sendable {
    public var onRubbishBinSettingsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>>
    
    public init(
        onRubbishBinSettingsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.onRubbishBinSettingsRequestFinish = onRubbishBinSettingsRequestFinish
    }
}

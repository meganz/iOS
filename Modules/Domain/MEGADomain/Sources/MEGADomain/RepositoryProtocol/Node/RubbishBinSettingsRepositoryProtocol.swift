import MEGASwift

public protocol RubbishBinSettingsRepositoryProtocol: Sendable {
    var onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> { get }
}

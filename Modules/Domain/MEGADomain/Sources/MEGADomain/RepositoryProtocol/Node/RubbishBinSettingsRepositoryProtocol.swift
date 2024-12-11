import MEGASwift

public protocol RubbishBinSettingsRepositoryProtocol: Sendable {
    var onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> { get }
    
    func cleanRubbishBin() async throws
    func catchupWithSDK() async throws
    func setRubbishBinAutopurgePeriod(in days: Int) async
}

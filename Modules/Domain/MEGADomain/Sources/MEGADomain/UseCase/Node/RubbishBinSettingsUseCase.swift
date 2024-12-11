import MEGASwift

public protocol RubbishBinSettingsUseCaseProtocol: Sendable {
    var onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> { get }
    
    func cleanRubbishBin() async throws
    func catchupWithSDK() async throws
    func setRubbishBinAutopurgePeriod(in days: Int) async
}

public struct RubbishBinSettingsUseCase<R: RubbishBinSettingsRepositoryProtocol>: RubbishBinSettingsUseCaseProtocol {
    private let rubbishBinSettingsRepository: R
    
    public var onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> {
        rubbishBinSettingsRepository.onRubbishBinSettinghsRequestFinish
    }
    
    public init(rubbishBinSettingsRepository: R) {
        self.rubbishBinSettingsRepository = rubbishBinSettingsRepository
    }
    
    public func cleanRubbishBin() async throws {
        try await rubbishBinSettingsRepository.cleanRubbishBin()
    }
    
    public func catchupWithSDK() async throws {
        try await rubbishBinSettingsRepository.catchupWithSDK()
    }
    
    public func setRubbishBinAutopurgePeriod(in days: Int) async {
        await rubbishBinSettingsRepository.setRubbishBinAutopurgePeriod(in: days)
    }
}

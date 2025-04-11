public protocol RubbishBinSettingsUseCaseProtocol: Sendable {
    func cleanRubbishBin() async throws
    func catchupWithSDK() async throws
    func setRubbishBinAutopurgePeriod(in days: Int) async
    func getRubbishBinAutopurgePeriod() async throws -> RubbishBinSettingsEntity
}

public struct RubbishBinSettingsUseCase<R: RubbishBinSettingsRepositoryProtocol>: RubbishBinSettingsUseCaseProtocol {
    private let rubbishBinSettingsRepository: R
    
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
    
    public func getRubbishBinAutopurgePeriod() async throws -> RubbishBinSettingsEntity {
        try await rubbishBinSettingsRepository.getRubbishBinAutopurgePeriod()
    }
}

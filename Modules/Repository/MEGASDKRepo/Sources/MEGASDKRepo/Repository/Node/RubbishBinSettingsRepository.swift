import MEGADomain
import MEGASwift

public struct RubbishBinSettingsRepository: RubbishBinSettingsRepositoryProtocol {
    private let rubbishBinSettingsUpdatesProvider: any RubbishBinSettingsUpdateProviderProtocol
    
    public var onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> {
        rubbishBinSettingsUpdatesProvider.onRubbishBinSettingsRequestFinish
    }
    
    public init(rubbishBinSettingsUpdatesProvider: some RubbishBinSettingsUpdateProviderProtocol) {
        self.rubbishBinSettingsUpdatesProvider = rubbishBinSettingsUpdatesProvider
    }
}

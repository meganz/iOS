import MEGADomain
import MEGASdk
import MEGASwift

public struct RubbishBinSettingsRepository: RubbishBinSettingsRepositoryProtocol {
    private let rubbishBinSettingsUpdatesProvider: any RubbishBinSettingsUpdateProviderProtocol
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk = MEGASdk.sharedSdk,
                rubbishBinSettingsUpdatesProvider: some RubbishBinSettingsUpdateProviderProtocol) {
        self.sdk = sdk
        self.rubbishBinSettingsUpdatesProvider = rubbishBinSettingsUpdatesProvider
    }
    
    public var onRubbishBinSettinghsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> {
        rubbishBinSettingsUpdatesProvider.onRubbishBinSettingsRequestFinish
    }
    
    public func cleanRubbishBin() async throws {
        return try await withAsyncThrowingValue { completion in
            sdk.cleanRubbishBin(with: RequestDelegate(completion: { _, error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }))
        }
    }
    
    public func catchupWithSDK() async throws {
        return try await withAsyncThrowingValue { completion in
            sdk.catchup(with: RequestDelegate(completion: { _, error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }))
        }
    }
    
    public func setRubbishBinAutopurgePeriod(in days: Int) async {
        sdk.setRubbishBinAutopurgePeriodInDays(days)
    }
}

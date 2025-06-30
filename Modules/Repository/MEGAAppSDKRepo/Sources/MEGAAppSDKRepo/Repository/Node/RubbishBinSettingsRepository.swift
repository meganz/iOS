import MEGADomain
import MEGASdk
import MEGASwift

public struct RubbishBinSettingsRepository: RubbishBinSettingsRepositoryProtocol {
    public static var newRepo: RubbishBinSettingsRepository {
        RubbishBinSettingsRepository(
            sdk: MEGASdk.sharedSdk,
            isPaidAccount: false,
            serverSideRubbishBinAutopurgeEnabled: false
        )
    }
    
    private let sdk: MEGASdk
    private let isPaidAccount: Bool
    private let serverSideRubbishBinAutopurgeEnabled: Bool
    
    public static let autopurgePeriodForPaidAccount = 90
    public static let autopurgePeriodForFreeAccount = 14
    
    public init(
        sdk: MEGASdk = MEGASdk.sharedSdk,
        isPaidAccount: Bool,
        serverSideRubbishBinAutopurgeEnabled: Bool
    ) {
        self.sdk = sdk
        self.isPaidAccount = isPaidAccount
        self.serverSideRubbishBinAutopurgeEnabled = serverSideRubbishBinAutopurgeEnabled
    }
    
    public func cleanRubbishBin() async throws {
        try await withAsyncThrowingVoidValue { completion in
            sdk.cleanRubbishBin(with: RequestDelegate { _, error in
                if error.type == .apiOk {
                    completion(.success(()))
                } else {
                    completion(.failure(error))
                }
            })
        }
    }
    
    public func catchupWithSDK() async throws {
        try await withAsyncThrowingVoidValue { completion in
            sdk.catchup(with: RequestDelegate(completion: { _, error in
                if error.type == .apiOk {
                    completion(.success(()))
                } else {
                    completion(.failure(error))
                }
            }))
        }
    }
    
    public func setRubbishBinAutopurgePeriod(in days: Int) async {
        sdk.setRubbishBinAutopurgePeriodInDays(days)
    }
    
    public func getRubbishBinAutopurgePeriod() async throws -> RubbishBinSettingsEntity {
        return try await withAsyncThrowingValue { completion in
            sdk.getRubbishBinAutopurgePeriod(
                with: RequestDelegate { result in
                    handleRubbishBinAutopurgeResult(result, completion: completion)
                }
            )
        }
    }
    
    private func handleRubbishBinAutopurgeResult(
        _ result: Result<MEGARequest, MEGAError>,
        completion: @escaping (Result<RubbishBinSettingsEntity, any Error>) -> Void
    ) {
        switch result {
        case .success(let request):
            handleSuccess(request, completion: completion)
        case .failure(let error):
            handleFailure(error, completion: completion)
        }
    }
    
    private func handleSuccess(
        _ request: MEGARequest,
        completion: @escaping (Result<RubbishBinSettingsEntity, any Error>) -> Void
    ) {
        guard request.number >= 0 else {
            completion(.failure(GenericErrorEntity()))
            return
        }
        let rubbishBinAutopurgePeriod = request.number
        let rubbishBinSettingsEntity = RubbishBinSettingsEntity(
            rubbishBinAutopurgePeriod: Int(rubbishBinAutopurgePeriod),
            rubbishBinCleaningSchedulerEnabled: rubbishBinAutopurgePeriod != 0
        )
        completion(.success(rubbishBinSettingsEntity))
    }
    
    private func handleFailure(
        _ error: MEGAError,
        completion: @escaping (Result<RubbishBinSettingsEntity, any Error>) -> Void
    ) {
        guard error.type == .apiENoent else {
            completion(.failure(GenericErrorEntity()))
            return
        }
        let rubbishBinAutopurgePeriod = isPaidAccount ? RubbishBinSettingsRepository.autopurgePeriodForPaidAccount : RubbishBinSettingsRepository.autopurgePeriodForFreeAccount
        let rubbishBinSettingsEntity = RubbishBinSettingsEntity(
            rubbishBinAutopurgePeriod: rubbishBinAutopurgePeriod,
            rubbishBinCleaningSchedulerEnabled: serverSideRubbishBinAutopurgeEnabled
        )
        completion(.success(rubbishBinSettingsEntity))
    }
}

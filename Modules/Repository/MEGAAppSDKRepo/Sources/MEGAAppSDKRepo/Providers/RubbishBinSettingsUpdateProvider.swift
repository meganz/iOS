import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

public protocol RubbishBinSettingsUpdateProviderProtocol: Sendable {
    /// Rubbish Bin Settings updates from `MEGARequestDelegate` `onRequestFinish` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call sdk.getRubbishBinAutopurgePeriod on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `Result<RubbishBinSettingsEntity, any Error>` until sequence terminated
    var onRubbishBinSettingsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> { get }
}

public struct RubbishBinSettingsUpdateProvider: RubbishBinSettingsUpdateProviderProtocol {
    private let sdk: MEGASdk
    private let isPaidAccount: Bool
    private let serverSideRubbishBinAutopurgeEnabled: Bool
    
    public static let autopurgePeriodForPaidAccount = 90
    public static let autopurgePeriodForFreeAccount = 14
    
    public init(sdk: MEGASdk = MEGASdk.sharedSdk, isPaidAccount: Bool, serverSideRubbishBinAutopurgeEnabled: Bool) {
        self.sdk = sdk
        self.isPaidAccount = isPaidAccount
        self.serverSideRubbishBinAutopurgeEnabled = serverSideRubbishBinAutopurgeEnabled
    }
    
    public var onRubbishBinSettingsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> {
        AsyncStream { continuation in
            let delegate = RubbishBingSettingsRequestDelegate(isPaidAccount: isPaidAccount,
                                                              serverSideRubbishBinAutopurgeEnabled: serverSideRubbishBinAutopurgeEnabled, onRequestFinish: { requestResult in
                continuation.yield(requestResult)
            })
            
            sdk.getRubbishBinAutopurgePeriod(with: delegate)
            
            continuation.onTermination = { @Sendable _ in
                sdk.removeMEGARequestDelegateAsync(delegate)
            }
        }
        .eraseToAnyAsyncSequence()
    }
}

private final class RubbishBingSettingsRequestDelegate: NSObject, Sendable {
    private let isPaidAccount: Bool
    private let serverSideRubbishBinAutopurgeEnabled: Bool
    private let onRequestFinish: @Sendable (Result<RubbishBinSettingsEntity, any Error>) -> Void
    
    init(isPaidAccount: Bool,
         serverSideRubbishBinAutopurgeEnabled: Bool,
         onRequestFinish: @Sendable @escaping (Result<RubbishBinSettingsEntity, any Error>) -> Void = { _ in }) {
        self.onRequestFinish = onRequestFinish
        self.isPaidAccount = isPaidAccount
        self.serverSideRubbishBinAutopurgeEnabled = serverSideRubbishBinAutopurgeEnabled
        
        super.init()
    }
}

extension RubbishBingSettingsRequestDelegate: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard (request.type == .MEGARequestTypeGetAttrUser || request.type == .MEGARequestTypeSetAttrUser)
                && (request.paramType == MEGAUserAttribute.rubbishTime.rawValue ) else { return }
        
        if error.type == .apiENoent {
            let rubbishBinAutopurgePeriod = isPaidAccount ?
            RubbishBinSettingsUpdateProvider.autopurgePeriodForPaidAccount :
            RubbishBinSettingsUpdateProvider.autopurgePeriodForFreeAccount
            let result = RubbishBinSettingsEntity(rubbishBinAutopurgePeriod: rubbishBinAutopurgePeriod,
                                                  rubbishBinCleaningSchedulerEnabled: serverSideRubbishBinAutopurgeEnabled)
            
            onRequestFinish(.success(result))
        } else if error.type == .apiOk {
            // Zero means that the rubbish-bin cleaning scheduler is disabled (only if the account is PRO). Any negative value means that the configured value is invalid.
            guard request.number >= 0 else { return }
            
            let rubbishBinAutopurgePeriod = request.number
            let result = RubbishBinSettingsEntity(rubbishBinAutopurgePeriod: Int(rubbishBinAutopurgePeriod),
                                                  rubbishBinCleaningSchedulerEnabled: rubbishBinAutopurgePeriod == 0 ? false : true)
            
            onRequestFinish(.success(result))
        }
    }
}

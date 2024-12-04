import Foundation
import MEGADomain
import MEGASdk
import MEGASwift

public protocol RubbishBinSettingsUpdateProviderProtocol: Sendable {
    /// Rubbish Bin Settings updates from `MEGARequestDelegate` `onRequestFinish` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `Result<RubbishBinSettingsEntity, any Error>` until sequence terminated
    var onRubbishBinSettingsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> { get }
}

public struct RubbishBinSettingsUpdateProvider: RubbishBinSettingsUpdateProviderProtocol {
    private let sdk: MEGASdk
    private let isProUser: Bool
    private let serverSideRubbishBinAutopurgeEnabled: Bool
    
    public init(sdk: MEGASdk = MEGASdk.sharedSdk, isProUser: Bool, serverSideRubbishBinAutopurgeEnabled: Bool) {
        self.sdk = sdk
        self.isProUser = isProUser
        self.serverSideRubbishBinAutopurgeEnabled = serverSideRubbishBinAutopurgeEnabled
    }
    
    public var onRubbishBinSettingsRequestFinish: AnyAsyncSequence<Result<RubbishBinSettingsEntity, any Error>> {
        AsyncStream { continuation in
            let delegate = RubbishBingSettingsRequestDelegate(isProUser: isProUser,
                                                              serverSideRubbishBinAutopurgeEnabled: serverSideRubbishBinAutopurgeEnabled, onRequestFinish: { requestResult in
                continuation.yield(requestResult)
            })
            
            sdk.getRubbishBinAutopurgePeriod(with: delegate)
            
            continuation.onTermination = { @Sendable _ in
                sdk.removeMEGARequestDelegateAsync(delegate )
            }
        }
        .eraseToAnyAsyncSequence()
    }
}

private final class RubbishBingSettingsRequestDelegate: NSObject, Sendable {
    private let isProUser: Bool
    private let serverSideRubbishBinAutopurgeEnabled: Bool
    private let onRequestFinish: @Sendable (Result<RubbishBinSettingsEntity, any Error>) -> Void
    
    init(isProUser: Bool,
         serverSideRubbishBinAutopurgeEnabled: Bool,
         onRequestFinish: @Sendable @escaping (Result<RubbishBinSettingsEntity, any Error>) -> Void = { _ in }) {
        self.onRequestFinish = onRequestFinish
        self.isProUser = isProUser
        self.serverSideRubbishBinAutopurgeEnabled = serverSideRubbishBinAutopurgeEnabled
        
        super.init()
    }
}

extension RubbishBingSettingsRequestDelegate: MEGARequestDelegate {
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        guard (request.type == .MEGARequestTypeGetAttrUser || request.type == .MEGARequestTypeSetAttrUser)
                && (request.paramType == MEGAUserAttribute.rubbishTime.rawValue ) else { return }
        
        if error.type == .apiENoent {
            let rubbishBinAutopurgePeriod = isProUser ? 90 : 14
            let result = RubbishBinSettingsEntity(rubbishBinAutopurgePeriod: Int64(rubbishBinAutopurgePeriod),
                                                  rubbishBinCleaningSchedulerEnabled: serverSideRubbishBinAutopurgeEnabled)
            
            onRequestFinish(.success(result))
        } else if error.type == .apiOk {
            // Zero means that the rubbish-bin cleaning scheduler is disabled (only if the account is PRO). Any negative value means that the configured value is invalid.
            guard request.number >= 0 else { return }
            
            let rubbishBinAutopurgePeriod = request.number
            let result = RubbishBinSettingsEntity(rubbishBinAutopurgePeriod: rubbishBinAutopurgePeriod,
                                                  rubbishBinCleaningSchedulerEnabled: rubbishBinAutopurgePeriod == 0 ? false : true)
            
            onRequestFinish(.success(result))
        }
    }
}

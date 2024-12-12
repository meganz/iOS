import MEGADomain
import MEGASdk

public final class FetchNodeDelegate: NSObject, MEGARequestDelegate {
    public var onStart: ((RequestEntity) -> Void)?
    public var onFetching: ((RequestEntity) -> Void)?
    public var onTemporaryError: ((RequestEntity, WaitingReasonEntity) -> Void)?
    private let onComplete: ((Result<RequestEntity, MEGAError>) -> Void)
        
    public init(onComplete: @escaping ((Result<RequestEntity, MEGAError>) -> Void)) {
        self.onComplete = onComplete
    }
    
    public func onRequestStart(
        _ api: MEGASdk,
        request: MEGARequest
    ) {
        onStart?(request.toRequestEntity())
    }
    
    public func onRequestFinish(
        _ api: MEGASdk,
        request: MEGARequest,
        error: MEGAError
    ) {
        if error.type == .apiOk {
            onComplete(.success(request.toRequestEntity()))
        } else {
            onComplete(.failure(error))
        }
    }
    
    public func onRequestUpdate(
        _ api: MEGASdk,
        request: MEGARequest
    ) {
        onFetching?(request.toRequestEntity())
    }
    
    public func onRequestTemporaryError(
        _ api: MEGASdk,
        request: MEGARequest,
        error: MEGAError
    ) {
        onTemporaryError?(
            request.toRequestEntity(),
            api.waiting.toWaitingReasonEntity()
        )
    }
}

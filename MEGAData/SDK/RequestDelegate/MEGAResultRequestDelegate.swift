final class MEGAResultRequestDelegate: NSObject, MEGARequestDelegate {
    
    private let completion: (Result<MEGARequest, MEGASDKErrorType>) -> Void
    
    init(completion: @escaping (Result<MEGARequest, MEGASDKErrorType>) -> Void) {
        self.completion = completion
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if let sdkError = error.sdkError {
            completion(.failure(sdkError))
            return
        }
        
        completion(.success(request))
    }
}

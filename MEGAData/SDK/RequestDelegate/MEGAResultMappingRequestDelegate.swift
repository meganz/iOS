final class MEGAResultMappingRequestDelegate<ResultValue, ResultError: Error>: NSObject, MEGARequestDelegate {
    
    private let completion: ((Result<ResultValue, ResultError>) -> Void)?
    
    private let mapValue: (MEGARequest) -> ResultValue
    
    private let mapError: (MEGASDKErrorType) -> ResultError
    
    init(
        completion: ((Result<ResultValue, ResultError>) -> Void)?,
        mapValue: @escaping (MEGARequest) -> ResultValue,
        mapError: @escaping (MEGASDKErrorType) -> ResultError
    ) {
        self.completion = completion
        self.mapValue = mapValue
        self.mapError = mapError
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if let sdkError = error.sdkError {
            completion?(.failure(mapError(sdkError)))
            return
        }
        
        completion?(.success(mapValue(request)))
    }
}

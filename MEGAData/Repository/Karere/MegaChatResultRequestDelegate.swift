final class MEGAChatResultRequestDelegate: NSObject, MEGAChatRequestDelegate {
    
    private let completion: (Result<MEGAChatRequest, CallsErrorEntity>) -> Void
    
    init(completion: @escaping (Result<MEGAChatRequest, CallsErrorEntity>) -> Void) {
        self.completion = completion
    }
    
    func onChatRequestFinish(_ api: MEGAChatSdk!, request: MEGAChatRequest!, error: MEGAChatError!) {
        if error.type == .MEGAChatErrorTypeOk {
            completion(.success(request))
        } else {
            completion(.failure(.generic))
        }
        
    }
}

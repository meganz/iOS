import MEGADomain

final class MEGAChatResultRequestDelegate: NSObject, MEGAChatRequestDelegate {
    
    private let completion: (Result<MEGAChatRequest, CallErrorEntity>) -> Void
    
    init(completion: @escaping (Result<MEGAChatRequest, CallErrorEntity>) -> Void) {
        self.completion = completion
    }
    
    func onChatRequestFinish(_ api: MEGAChatSdk!, request: MEGAChatRequest!, error: MEGAChatError!) {
        if let request = request,
           error?.type == .MEGAChatErrorTypeOk {
            completion(.success(request))
        } else {
            completion(.failure(.generic))
        }
    }
}


public typealias MEGAChatRequestCompletion = (_ result: Result<MEGAChatRequest, MEGAChatError>) -> Void

public class ChatRequestDelegate: NSObject, MEGAChatRequestDelegate {
    let completion: MEGAChatRequestCompletion
    
    public init(completion: @escaping MEGAChatRequestCompletion) {
        self.completion = completion
        super.init()
    }
        
    public func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        if error.type == .MEGAChatErrorTypeOk {
            self.completion(.success(request))
        } else {
            self.completion(.failure(error))
        }
    }
}

import MEGAChatSdk

public typealias MEGAChatRequestCompletion = (_ result: Result<MEGAChatRequest, MEGAChatError>) -> Void

public class ChatRequestDelegate: NSObject, MEGAChatRequestDelegate {
    let completion: MEGAChatRequestCompletion
    private let successCodes: [MEGAChatErrorType]
    
    public init(successCodes: [MEGAChatErrorType] = [.MEGAChatErrorTypeOk], completion: @escaping MEGAChatRequestCompletion) {
        self.completion = completion
        self.successCodes = successCodes
        super.init()
    }
    
    public func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        if successCodes.contains(error.type) {
            self.completion(.success(request))
        } else {
            self.completion(.failure(error))
        }
    }
}

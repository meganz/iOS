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
    
    @objc public convenience init(completion: @escaping (MEGAChatRequest?, MEGAChatError?) -> Void) {
        let completion: MEGAChatRequestCompletion = { result in
            switch result {
            case let .success(request):
                completion(request, nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
        self.init(completion: completion)
    }
    
    public func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        if successCodes.contains(error.type) {
            self.completion(.success(request))
        } else {
            self.completion(.failure(error))
        }
    }
}

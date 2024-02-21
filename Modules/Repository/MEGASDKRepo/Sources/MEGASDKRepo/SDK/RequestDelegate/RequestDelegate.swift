import Foundation
import MEGASdk

public typealias MEGARequestCompletion = (_ result: Result<MEGARequest, MEGAError>) -> Void

public class RequestDelegate: NSObject, MEGARequestDelegate {
    let completion: MEGARequestCompletion
    private let successCodes: [MEGAErrorType]
    
    public init(successCodes: [MEGAErrorType] = [.apiOk], completion: @escaping MEGARequestCompletion) {
        self.successCodes = successCodes
        self.completion = completion
        super.init()
    }
    
    @objc public convenience init(completion: @escaping (MEGARequest?, MEGAError?) -> Void) {
        let completion: MEGARequestCompletion = { result in
            switch result {
            case let .success(request):
                completion(request, nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
        self.init(completion: completion)
    }
    
    public func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if successCodes.contains(error.type) {
            self.completion(.success(request))
        } else {
            self.completion(.failure(error))
        }
    }
}

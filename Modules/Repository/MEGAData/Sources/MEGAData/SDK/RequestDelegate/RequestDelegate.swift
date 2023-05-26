import Foundation
import MEGASdk

public typealias MEGARequestCompletion = (_ result: Result<MEGARequest, MEGAError>) -> Void

public class RequestDelegate: NSObject, MEGARequestDelegate {
    let completion: MEGARequestCompletion
    
    public init(completion: @escaping MEGARequestCompletion) {
        self.completion = completion
    }
    
    public func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type == .apiOk {
            self.completion(.success(request))
        } else {
            self.completion(.failure(error))
        }
    }
}

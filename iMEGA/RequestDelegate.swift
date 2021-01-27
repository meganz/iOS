import Foundation

typealias MEGARequestCompletion = (_ result: Result<MEGARequest, MEGAError>) -> Void

class RequestDelegate: NSObject, MEGARequestDelegate {
    let completion: MEGARequestCompletion
    
    init(completion: @escaping MEGARequestCompletion) {
        self.completion = completion
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type == .apiOk {
            self.completion(.success(request))
        } else {
            self.completion(.failure(error))
        }
    }
}

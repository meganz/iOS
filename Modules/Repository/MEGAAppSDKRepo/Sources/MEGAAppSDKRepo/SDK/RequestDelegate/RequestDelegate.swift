import Foundation
import MEGASdk
import MEGASDKRepo

public typealias MEGARequestCompletion = (Result<MEGARequest, MEGAError>) -> Void
public typealias MEGARequestStartHandler = (MEGARequest) -> Void

public class RequestDelegate: NSObject, MEGARequestDelegate {
    let completion: MEGARequestCompletion
    
    public init(completion: @escaping MEGARequestCompletion) {
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
        if error.type == .apiOk {
            self.completion(.success(request))
        } else {
            self.completion(.failure(error))
        }
    }
}

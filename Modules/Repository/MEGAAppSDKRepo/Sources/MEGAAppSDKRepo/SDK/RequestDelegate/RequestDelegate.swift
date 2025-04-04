import Foundation
import MEGASdk

public typealias MEGARequestCompletion = (_ result: Result<MEGARequest, MEGAError>) -> Void
public typealias MEGARequestStartHandler = (MEGARequest) -> Void

public class RequestDelegate: NSObject, MEGARequestDelegate {
    let completion: MEGARequestCompletion
    let onRequestStartHandler: MEGARequestStartHandler?
    
    private let successCodes: [MEGAErrorType]
    
    public init(successCodes: [MEGAErrorType] = [.apiOk], onRequestStartHandler: MEGARequestStartHandler? = nil, completion: @escaping MEGARequestCompletion) {
        self.successCodes = successCodes
        self.completion = completion
        self.onRequestStartHandler = onRequestStartHandler
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
    
    @objc public convenience init(onRequestStartHandler: @escaping (MEGARequest) -> Void, completion: @escaping (MEGARequest?, MEGAError?) -> Void) {
        let completion: MEGARequestCompletion = { result in
            switch result {
            case let .success(request):
                completion(request, nil)
            case let .failure(error):
                completion(nil, error)
            }
        }
        let onRequestStartHandler: MEGARequestStartHandler = { request in
            onRequestStartHandler(request)
        }
        self.init(onRequestStartHandler: onRequestStartHandler, completion: completion)
    }
    
    public func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if successCodes.contains(error.type) {
            self.completion(.success(request))
        } else {
            self.completion(.failure(error))
        }
    }
    
    public func onRequestStart(_ api: MEGASdk, request: MEGARequest) {
        if let onRequestStartHandler {
            onRequestStartHandler(request)
        }
    }
}

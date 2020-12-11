import Foundation

extension MEGAError {
    func toHeartbeatError() -> NSError {
        NSError(domain: "nz.mega.heartbeat", code: type.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey : name ?? ""])
    }
}

typealias MEGARequestCompletion = (_ result: Result<MEGARequest, Error>) -> Void

final class HeartbeatRequestDelegate: NSObject, MEGARequestDelegate {
    private let completion: MEGARequestCompletion
    
    init(completion: @escaping MEGARequestCompletion) {
        self.completion = completion
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        DispatchQueue.global(qos: .utility).async {
            if error.type == .apiOk {
                self.completion(.success(request))
            } else {
                self.completion(.failure(error.toHeartbeatError()))
            }
        }
    }
}


import Foundation

extension MEGAError {
    func toHeartbeatError(backupIdBase64String: String) -> NSError {
        NSError(domain: "nz.mega.heartbeat",
                code: type.rawValue,
                userInfo: [NSLocalizedFailureReasonErrorKey: name ?? "",
                           "BackupId": backupIdBase64String])
    }
}

typealias HeartbeatRequestCompletion = (_ result: Result<MEGARequest, Error>) -> Void

final class HeartbeatRequestDelegate: NSObject, MEGARequestDelegate {
    private let completion: HeartbeatRequestCompletion
    
    init(completion: @escaping HeartbeatRequestCompletion) {
        self.completion = completion
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type == .apiOk {
            self.completion(.success(request))
        } else {
            self.completion(.failure(error.toHeartbeatError(backupIdBase64String: type(of: api).base64Handle(forHandle: request.parentHandle) ?? "")))
        }
    }
}

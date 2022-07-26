
final class InviteRequestDelegate: NSObject, MEGARequestDelegate {
    typealias Completion = (_ result: Result<Void, InviteErrorEntity>) -> Void
    private let completion: Completion
    
    init(completion: @escaping Completion) {
        self.completion = completion
    }
    
    func onRequestFinish(_ api: MEGASdk, request: MEGARequest, error: MEGAError) {
        if error.type == .apiOk {
            completion(.success(()))
        } else {
            switch error.type {
            case .apiEArgs where request.email == api.myEmail:
                completion(.failure(.ownEmailEntered))
            case .apiEExist:
                if let user = api.contact(forEmail: request.email), user.visibility == .visible {
                    completion(.failure(.alreadyAContact))
                } else {
                    let outgoingContactRequests = api.outgoingContactRequests()
                    let contactRequests = (0..<outgoingContactRequests.size.intValue).compactMap {
                        outgoingContactRequests.contactRequest(at: $0)
                    }
                    let isInOutgoingContactRequest = contactRequests.contains { $0.targetEmail == request.email }
                    let errorString = String(format: "%@ %@", request.requestString ?? "", error.name ?? "")
                    completion(.failure(isInOutgoingContactRequest ? .isInOutgoingContactRequest : .generic(errorString)))
                }
            default:
                let errorString = String(format: "%@ %@", request.requestString ?? "", error.name ?? "")
                completion(.failure(.generic(errorString)))
            }
        }
    }
}

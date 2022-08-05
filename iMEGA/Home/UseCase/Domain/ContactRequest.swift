import Foundation
import MEGADomain

struct ContactRequest {

    let handle: HandleEntity

    let sourceEmail: String?

    let sourceMessage: String?

    let targetEmail: String?

    let creationTime: Date

    let modificationTime: Date

    let isOutgoing: Bool

    let status: Status?

    enum Status: Int {
        case unresolved = 0
        case accepted   = 1
        case denied
        case ignored
        case deleted
        case reminded

        init?(from megaContactRequestStatus: MEGAContactRequestStatus) {
            self.init(rawValue: Int(megaContactRequestStatus.rawValue))
        }
    }
}

extension ContactRequest {

    init(from megaContactRequest: MEGAContactRequest) {
        self.handle = megaContactRequest.handle
        self.sourceEmail = megaContactRequest.sourceEmail
        self.sourceMessage = megaContactRequest.sourceMessage
        self.targetEmail = megaContactRequest.targetEmail
        self.creationTime = megaContactRequest.creationTime
        self.modificationTime = megaContactRequest.modificationTime
        self.isOutgoing = megaContactRequest.isOutgoing()
        self.status = Status(from: megaContactRequest.status)
    }
}

import MEGADomain
import MEGASdk

extension MEGAContactRequestList {
    public func toContactRequestEntities() -> [ContactRequestEntity] {
        (0..<size.intValue).compactMap { contactRequest(at: $0)?.toContactRequestEntity() }
    }
}

extension MEGAContactRequest {
    public func toContactRequestEntity() -> ContactRequestEntity {
        ContactRequestEntity(contactRequest: self)
    }
}

fileprivate extension ContactRequestEntity {
    init(contactRequest: MEGAContactRequest) {
        self.init(
            handle: contactRequest.handle,
            sourceEmail: contactRequest.sourceEmail,
            sourceMessage: contactRequest.sourceMessage,
            targetEmail: contactRequest.targetEmail,
            creationTime: contactRequest.creationTime,
            modificationTime: contactRequest.modificationTime,
            isOutgoing: contactRequest.isOutgoing(),
            status: contactRequest.status.toContactRequestStatus()
        )
    }
}

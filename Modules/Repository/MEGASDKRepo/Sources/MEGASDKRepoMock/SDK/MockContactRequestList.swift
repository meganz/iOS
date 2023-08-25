import MEGASdk

public final class MockContactRequestList: MEGAContactRequestList {
    private let contactRequests: [MEGAContactRequest]
    
    public init(contactRequests: [MEGAContactRequest] = []) {
        self.contactRequests = contactRequests
    }
    
    public override var size: NSInteger { contactRequests.count }
    
    public override func contactRequest(at index: Int) -> MEGAContactRequest? {
        contactRequests[safe: index]
    }
}

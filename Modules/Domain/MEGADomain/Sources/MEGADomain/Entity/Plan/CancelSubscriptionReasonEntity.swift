public struct CancelSubscriptionReasonEntity: Sendable, Equatable {
    public let text: String
    public let position: String
    
    public init(text: String, position: String) {
        self.text = text
        self.position = position
    }
}

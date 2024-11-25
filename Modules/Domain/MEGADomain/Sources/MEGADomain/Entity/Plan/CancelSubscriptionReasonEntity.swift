public struct CancelSubscriptionReasonEntity: Sendable {
    public let text: String
    public let position: String
    
    public init(text: String, position: String) {
        self.text = text
        self.position = position
    }
}


public struct FeedbackEntity: Sendable {
    public let toEmail: String
    public let subject: String
    public let messageBody: String
    public let logsFileName: String
    
    public init(toEmail: String, subject: String, messageBody: String, logsFileName: String) {
        self.toEmail = toEmail
        self.subject = subject
        self.messageBody = messageBody
        self.logsFileName = logsFileName
    }
}

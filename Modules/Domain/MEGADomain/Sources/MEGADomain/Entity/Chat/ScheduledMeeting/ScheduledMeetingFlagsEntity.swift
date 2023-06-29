import Foundation

public struct ScheduledMeetingFlagsEntity: Sendable {
    public let emailsEnabled: Bool
    
    public init(emailsEnabled: Bool = false) {
        self.emailsEnabled = emailsEnabled
    }
}

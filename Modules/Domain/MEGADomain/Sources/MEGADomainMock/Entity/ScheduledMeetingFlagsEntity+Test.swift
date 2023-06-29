import MEGADomain

public extension ScheduledMeetingFlagsEntity {
    init(emailsEnabled: Bool = false, isTesting: Bool = true) {
        self.init(emailsEnabled: emailsEnabled)
    }
}

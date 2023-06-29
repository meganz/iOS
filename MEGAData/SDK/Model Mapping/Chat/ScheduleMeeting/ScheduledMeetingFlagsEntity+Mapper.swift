import MEGADomain

extension ScheduledMeetingFlagsEntity {
    init(with flags: MEGAChatScheduledFlags) {
        self.init(
            emailsEnabled: flags.emailsEnabled
        )
    }
    
    func toMEGAChatScheduledFlags() -> MEGAChatScheduledFlags {
        MEGAChatScheduledFlags(sendEmails: emailsEnabled)
    }
}

extension MEGAChatScheduledFlags {
    func toScheduledMeetingFlagsEntity() -> ScheduledMeetingFlagsEntity {
        ScheduledMeetingFlagsEntity(with: self)
    }
}

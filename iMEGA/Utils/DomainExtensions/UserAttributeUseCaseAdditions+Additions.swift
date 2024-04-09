import MEGADomain

extension UserAttributeUseCaseProtocol {
    func onboardingRecord() async throws -> ScheduledMeetingOnboardingTipRecord? {
        guard let smotAttributes = try await retrieveScheduledMeetingOnBoardingAttrubute() else { return nil }
        let currentTip = ScheduledMeetingOnboardingTip.toScheduledMeetingOnboardingTip(from: smotAttributes.ios.record.currentTip)
        return ScheduledMeetingOnboardingTipRecord(currentTip: currentTip)
    }
}

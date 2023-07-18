import MEGADomain

extension UserAttributeUseCaseProtocol {
    func timelineFilter() async throws -> TimelineFilter? {
        guard let ccAttributes = try await retrieveContentConsumptionAttribute() else { return nil }
        return TimelineFilter(
            filterType: PhotosFilterType.toFilterType(from: ccAttributes.ios.timeline.mediaType),
            filterLocation: PhotosFilterLocation.toFilterLocation(from: ccAttributes.ios.timeline.location),
            usePreference: ccAttributes.ios.timeline.usePreference ?? false)
    }
    
    func onboardingRecord() async throws -> ScheduledMeetingOnboardingTipRecord? {
        guard let smotAttributes = try await retrieveScheduledMeetingOnBoardingAttrubute() else { return nil }
        let currentTip = ScheduledMeetingOnboardingTip.toScheduledMeetingOnboardingTip(from: smotAttributes.ios.record.currentTip)
        return ScheduledMeetingOnboardingTipRecord(currentTip: currentTip)
    }
}

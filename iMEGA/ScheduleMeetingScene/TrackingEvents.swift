import MEGAAnalyticsiOS

// hosts new events that tracked in relation to [MEET-3644]
// other events should be migrated here to simplify the interface of the ScheduleMeetingViewConfigurable
extension ScheduleMeetingViewModel {
    
    struct TrackingEvents {
        var screenEvent: any EventIdentifier
        var meetingLinkEnabled: any EventIdentifier
        
        static var editOccurence: Self {
            .init(
                screenEvent: EditScheduledMeetingOccurrenceScreenEvent(),
                meetingLinkEnabled: EditScheduledMeetingOccurrenceSettingEnableMeetingLinkButtonEvent()
            )
        }
        
        static var editMeeting: Self {
            .init(
                screenEvent: EditScheduledMeetingScreenEvent(),
                meetingLinkEnabled: EditScheduledMeetingSettingEnableMeetingLinkButtonEvent()
            )
        }
        
        static var newMeeting: Self {
            .init(
                screenEvent: ScheduleNewMeetingScreenEvent(),
                meetingLinkEnabled: ScheduledMeetingSettingEnableMeetingLinkButtonEvent()
            )
        }
    }
    
}

import Foundation
import MEGADomain

public final class MockUserAttributeUseCase: UserAttributeUseCaseProtocol {
    public var userAttribute: [UserAttributeEntity: String]
    public var userAttributeContainer: [UserAttributeEntity: [String: String]]
    public var contentConsumption: ContentConsumptionEntity?
    public var scheduleMeetingOnboarding: ScheduledMeetingOnboardingEntity?
    
    public init(
        userAttribute: [UserAttributeEntity: String] = [:],
        userAttributeContainer: [UserAttributeEntity: [String: String]] = [:],
        contentConsumption: ContentConsumptionEntity? = nil,
        scheduleMeetingOnboarding: ScheduledMeetingOnboardingEntity? = nil
    ) {
        self.userAttribute = userAttribute
        self.userAttributeContainer = userAttributeContainer
        self.contentConsumption = contentConsumption
        self.scheduleMeetingOnboarding = scheduleMeetingOnboarding
    }
    
    public func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws {
        userAttribute[attribute] = value
    }
    
    public func updateUserAttribute(_ attribute: UserAttributeEntity, key: String, value: String) async throws {
        if userAttributeContainer[attribute] != nil {
            userAttributeContainer[attribute]?[key] = value
        } else {
            userAttributeContainer[attribute] = [key: value]
        }
    }
    
    public func userAttribute(for attribute: UserAttributeEntity) async throws -> [String: String]? {
        userAttributeContainer[attribute]
    }
    
    public func saveTimelineFilter(key: String, timeline: ContentConsumptionTimeline) async throws {
        userAttributeContainer[.contentConsumptionPreferences] = [key: "\(timeline.mediaType.rawValue)-\(timeline.location.rawValue)"]
    }
    
    public func retrieveContentConsumptionAttribute() async throws -> ContentConsumptionEntity? {
        contentConsumption
    }
    
    public func saveScheduledMeetingOnBoardingRecord(key: String, record: ScheduledMeetingOnboardingRecord) async throws {
        userAttributeContainer[.appsPreferences] = [key: "\(record.currentTip)"]
    }
    
    public func retrieveScheduledMeetingOnBoardingAttrubute() async throws -> ScheduledMeetingOnboardingEntity? {
        scheduleMeetingOnboarding
    }
}

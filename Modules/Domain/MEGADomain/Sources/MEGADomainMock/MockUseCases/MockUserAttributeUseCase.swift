import Foundation
import MEGADomain

public final class MockUserAttributeUseCase: UserAttributeUseCaseProtocol, @unchecked Sendable {
    public var userAttribute: [UserAttributeEntity: String]
    public var userAttributeContainer: [UserAttributeEntity: [String: String]]
    public var contentConsumption: ContentConsumptionEntity?
    public var scheduleMeetingOnboarding: ScheduledMeetingOnboardingEntity?
    public var raiseHandNewFeatureBadge: RaiseHandNewFeatureBadgeEntity?

    public init(
        userAttribute: [UserAttributeEntity: String] = [:],
        userAttributeContainer: [UserAttributeEntity: [String: String]] = [:],
        contentConsumption: ContentConsumptionEntity? = nil,
        scheduleMeetingOnboarding: ScheduledMeetingOnboardingEntity? = nil,
        raiseHandNewFeatureBadge: RaiseHandNewFeatureBadgeEntity? = nil
    ) {
        self.userAttribute = userAttribute
        self.userAttributeContainer = userAttributeContainer
        self.contentConsumption = contentConsumption
        self.scheduleMeetingOnboarding = scheduleMeetingOnboarding
        self.raiseHandNewFeatureBadge = raiseHandNewFeatureBadge
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
    
    public func saveScheduledMeetingOnBoardingRecord(key: String, record: ScheduledMeetingOnboardingRecord) async throws {
        userAttributeContainer[.appsPreferences] = [key: "\(record.currentTip)"]
    }
    
    public func retrieveScheduledMeetingOnBoardingAttrubute() async throws -> ScheduledMeetingOnboardingEntity? {
        scheduleMeetingOnboarding
    }
    
    public func saveRaiseHandNewFeatureBadge(presentedTimes: Int) async throws {
        userAttributeContainer[.appsPreferences] = [RaiseHandNewFeatureBadgeKeyEntity.key: "\(presentedTimes)"]
    }
    
    public func retrieveRaiseHandAttribute() async throws -> RaiseHandNewFeatureBadgeEntity? {
        raiseHandNewFeatureBadge
    }
    
    public func saveNoteToSelfNewFeatureBadge(presentedTimes: Int) async throws {
        userAttributeContainer[.appsPreferences] = [RaiseHandNewFeatureBadgeKeyEntity.key: "\(presentedTimes)"]
    }
    
    public func retrieveNoteToSelfNewFeatureBadgeAttribute() async throws -> NoteToSelfNewFeatureBadgeEntity? {
        guard let presentedTimesString = userAttributeContainer[.appsPreferences]?[RaiseHandNewFeatureBadgeKeyEntity.key],
              let presentedTimesInt = Int(presentedTimesString)
        else {
            throw GenericErrorEntity()
        }
        return NoteToSelfNewFeatureBadgeEntity(presentedCount: presentedTimesInt)
    }
    
    public func getUserAttribute(for attribute: UserAttributeEntity) async throws -> String? {
        nil
    }
}

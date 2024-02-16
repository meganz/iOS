import MEGADomain

struct Preview_UserAttributeUseCase: UserAttributeUseCaseProtocol {
    func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws {
        
    }
    
    func updateUserAttribute(_ attribute: UserAttributeEntity, key: String, value: String) async throws {
        
    }
    
    func userAttribute(for attribute: UserAttributeEntity) async throws -> [String: String]? {
        nil
    }
    
    func retrieveContentConsumptionAttribute() async throws -> ContentConsumptionEntity? {
        nil
    }
    
    func saveTimelineFilter(key: String, timeline: ContentConsumptionTimeline) async throws {
        
    }
    
    func retrieveScheduledMeetingOnBoardingAttrubute() async throws -> ScheduledMeetingOnboardingEntity? {
        nil
    }
    
    func saveScheduledMeetingOnBoardingRecord(key: String, record: ScheduledMeetingOnboardingRecord) async throws {
        
    }
}

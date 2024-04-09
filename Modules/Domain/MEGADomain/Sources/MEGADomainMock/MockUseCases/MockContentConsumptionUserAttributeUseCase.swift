import Foundation
import MEGADomain

public final class MockContentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCaseProtocol {
    
    public private(set) var timelineUserAttributeEntity: TimelineUserAttributeEntity
    
    public init(timelineUserAttributeEntity: TimelineUserAttributeEntity = .init(mediaType: .allMedia, location: .allLocations, usePreference: false)) {
        
        self.timelineUserAttributeEntity = timelineUserAttributeEntity
    }
    
    public func fetchTimelineAttribute() async -> TimelineUserAttributeEntity {
        timelineUserAttributeEntity
    }
    
    public func save(timeline: TimelineUserAttributeEntity) async throws {
        self.timelineUserAttributeEntity = timeline
    }
}

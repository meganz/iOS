import Foundation
import MEGADomain

public final class MockUserAttributeUseCase: UserAttributeUseCaseProtocol {
    public var userAttribute: [UserAttributeEntity: String]
    public var userAttributeContainer: [UserAttributeEntity: [String: String]]
    public var contentConsumption: ContentConsumptionEntity?
    
    public init(
        userAttribute: [UserAttributeEntity: String] = [:],
        userAttributeContainer: [UserAttributeEntity: [String: String]] = [:],
        contentConsumption: ContentConsumptionEntity? = nil
    ) {
        self.userAttribute = userAttribute
        self.userAttributeContainer = userAttributeContainer
        self.contentConsumption = contentConsumption
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
        userAttributeContainer[.appsPreferences] = [key: "\(timeline.mediaType.rawValue)-\(timeline.location.rawValue)"]
    }
    
    public func retrieveContentConsumptionAttribute() async throws -> ContentConsumptionEntity? {
        contentConsumption
    }
}

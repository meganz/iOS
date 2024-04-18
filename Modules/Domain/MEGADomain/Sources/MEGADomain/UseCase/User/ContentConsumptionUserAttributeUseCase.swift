import Foundation

public protocol ContentConsumptionUserAttributeUseCaseProtocol: Sendable {
    
    /// Fetch stored user attributes associated with Timeline.
    /// The returned object TimelineUserAttributeEntity is an accumulation of all attributes stored in users account attributes associated to timeline. This can include both account and account-platform specific values.
    /// - Returns: TimelineUserAttributeEntity contains all the stored user attribute for timeline, if no stored object exists a default structure will be provided.
    func fetchTimelineAttribute() async -> TimelineUserAttributeEntity
    
    /// Fetch stored user attributes associated with SensitiveNodes
    /// The returned object SensitiveNodesUserAttributeEntity is an accumulation of all attributes stored in users account attributes associated to sensitive. This can include both account and account-platform specific values.
    /// - Returns: SensitiveNodesUserAttributeEntity contains all the stored user attribute for sensitive node,, if no stored object exists a default structure will be provided.
    func fetchSensitiveAttribute() async -> SensitiveNodesUserAttributeEntity
    
    ///  Save the provided TimelineUserAttributeEntity into users attributes.
    /// - Parameter timeline: TimelineUserAttributeEntity object containing attributes to be saved.
    func save(timeline: TimelineUserAttributeEntity) async throws
    
    ///  Save the provided sensitive setting `showHiddenNodes` into users attributes.
    /// - Parameter showHiddenNodes: Bool attributes to be saved.
    func saveSensitiveSetting(showHiddenNodes: Bool) async throws
    
    ///  Save the provided sensitive setting `onboarded` into users attributes.
    /// - Parameter showHiddenNodes: Bool attributes to be saved.
    func saveSensitiveSetting(onboarded: Bool) async throws
}

public struct ContentConsumptionUserAttributeUseCase<T: UserAttributeRepositoryProtocol>: ContentConsumptionUserAttributeUseCaseProtocol {
    
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func fetchTimelineAttribute() async -> TimelineUserAttributeEntity {
        await retrieveContentConsumptionAttribute()
            .toTimelineUserAttributeEntity()
    }
    
    public func fetchSensitiveAttribute() async -> SensitiveNodesUserAttributeEntity {
        await retrieveContentConsumptionAttribute()
            .toSensitiveNodesUserAttributeEntity()
    }
    
    public func save(timeline: TimelineUserAttributeEntity) async throws {
        let attributes = await retrieveContentConsumptionAttribute()
            .update(timeline: timeline)
        
        try await save(attributes: attributes)
    }
        
    public func saveSensitiveSetting(showHiddenNodes: Bool) async throws {
        let attributes = await retrieveContentConsumptionAttribute()
            .updateSensitive(showHiddenNodes: showHiddenNodes)
        
        try await save(attributes: attributes)
    }
    
    public func saveSensitiveSetting(onboarded: Bool) async throws {
        let attributes = await retrieveContentConsumptionAttribute()
            .updateSensitive(onboarded: onboarded)
        
        try await save(attributes: attributes)
    }
}

// MARK: Private methods
extension ContentConsumptionUserAttributeUseCase {
    
    private func save(attributes: ContentConsumptionEntity) async throws {
        try await repo.mergeUserAttribute(.contentConsumptionPreferences,
                                              key: ContentConsumptionKeysEntity.key,
                                              object: attributes)
    }
    
    private func retrieveContentConsumptionAttribute() async -> ContentConsumptionEntity {
        guard let cc: ContentConsumptionEntity = try? await repo.userAttribute(
            for: .contentConsumptionPreferences,
            key: ContentConsumptionKeysEntity.key) else {
            return .default
        }
        return cc
    }
}

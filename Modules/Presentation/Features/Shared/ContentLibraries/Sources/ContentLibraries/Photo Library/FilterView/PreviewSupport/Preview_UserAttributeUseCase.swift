import MEGADomain

struct Preview_ContentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCaseProtocol {
    func fetchTimelineAttribute() async -> TimelineUserAttributeEntity {
        .init(mediaType: .allMedia, location: .allLocations, usePreference: false)
    }

    func fetchSensitiveAttribute() async -> SensitiveNodesUserAttributeEntity {
        .init(onboarded: false, showHiddenNodes: false)
    }
        
    func save(timeline: TimelineUserAttributeEntity) async throws { }
    func saveSensitiveSetting(showHiddenNodes: Bool) async throws { }
    func saveSensitiveSetting(onboarded: Bool) async throws { }
}

import MEGADomain

struct Preview_ContentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCaseProtocol {
    func fetchTimelineAttribute() async -> TimelineUserAttributeEntity {
        .init(mediaType: .allMedia, location: .allLocations, usePreference: false)
    }

    func save(timeline: TimelineUserAttributeEntity) async throws { }
}

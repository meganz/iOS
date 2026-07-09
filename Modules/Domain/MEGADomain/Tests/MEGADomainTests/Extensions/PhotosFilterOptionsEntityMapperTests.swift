import MEGADomain
import Testing

struct PhotosFilterOptionsEntityMapperTests {

    @Test(arguments: [
        (PhotosFilterOptionsEntity.allLocations, Optional<TimelineUserAttributeEntity.MediaType>.none),
        (.allMedia, .allMedia),
        (.images, .images),
        (.videos, .videos)
    ])
    func mediaType(for filterOption: PhotosFilterOptionsEntity, expected: TimelineUserAttributeEntity.MediaType?) {
        #expect(filterOption.toTimelineUserAttributeMediaTypeEntity() == expected)
    }
    
    @Test(arguments: [
        (PhotosFilterOptionsEntity.allMedia, Optional<TimelineUserAttributeEntity.MediaLocation>.none),
        (.allLocations, .allLocations),
        (.cameraUploads, .cameraUploads),
        (.cloudDrive, .cloudDrive)
    ])
    func location(for filterOption: PhotosFilterOptionsEntity, expected: TimelineUserAttributeEntity.MediaLocation?) {
        #expect(filterOption.toTimelineUserAttributeMediaLocationEntity() == expected)
    }

    @Test(arguments: [
        // Independent media/location parts, including combined sets and fallbacks.
        (PhotosFilterOptionsEntity([.allMedia, .allLocations]),
         MediaTimelineFilterEntity(mediaType: .allMedia, location: .allLocations)),
        (PhotosFilterOptionsEntity([.images, .cloudDrive]),
         MediaTimelineFilterEntity(mediaType: .images, location: .cloudDrive)),
        (PhotosFilterOptionsEntity([.videos, .cameraUploads]),
         MediaTimelineFilterEntity(mediaType: .videos, location: .cameraUploads)),
        // Empty selection falls back to all-media / all-locations.
        (PhotosFilterOptionsEntity([]),
         MediaTimelineFilterEntity(mediaType: .allMedia, location: .allLocations))
    ])
    func mediaTimelineFilter(for filterOption: PhotosFilterOptionsEntity, expected: MediaTimelineFilterEntity) {
        #expect(filterOption.toMediaTimelineFilterEntity() == expected)
    }
}

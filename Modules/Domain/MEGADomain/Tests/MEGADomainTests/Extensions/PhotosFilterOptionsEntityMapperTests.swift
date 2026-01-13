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
}

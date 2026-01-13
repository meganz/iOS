import MEGADomain
import Testing

struct TimelineUserAttributeEntityMapperTests {

    @Test(arguments: [
        // allMedia combinations
        (TimelineUserAttributeEntity.MediaType.allMedia, TimelineUserAttributeEntity.MediaLocation.allLocations, combined(mediaType: .allMedia, location: .allLocations)),
        (.allMedia, .cloudDrive, combined(mediaType: .allMedia, location: .cloudDrive)),
        (.allMedia, .cameraUploads, combined(mediaType: .allMedia, location: .cameraUploads)),
        
        // images combinations
        (.images, .allLocations, combined(mediaType: .images, location: .allLocations)),
        (.images, .cloudDrive, combined(mediaType: .images, location: .cloudDrive)),
        (.images, .cameraUploads, combined(mediaType: .images, location: .cameraUploads)),
        
        // videos combinations
        (.videos, .allLocations, combined(mediaType: .videos, location: .allLocations)),
        (.videos, .cloudDrive, combined(mediaType: .videos, location: .cloudDrive)),
        (.videos, .cameraUploads, combined(mediaType: .videos, location: .cameraUploads))
    ])
    func photoFilterOptions(
        mediaType: TimelineUserAttributeEntity.MediaType,
        location: TimelineUserAttributeEntity.MediaLocation,
        expected: PhotosFilterOptionsEntity
    ) {
        let sut = TimelineUserAttributeEntity(
            mediaType: mediaType,
            location: location,
            usePreference: true)
        
        #expect(sut.toPhotoFilterOptionsEntity() == expected)
    }
    
    private static func combined(
        mediaType: PhotosFilterOptionsEntity,
        location: PhotosFilterOptionsEntity
    ) -> PhotosFilterOptionsEntity {
        [mediaType, location]
    }
}

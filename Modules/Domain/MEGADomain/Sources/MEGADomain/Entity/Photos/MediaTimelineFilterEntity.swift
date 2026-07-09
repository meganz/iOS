/// Scope of a media-timeline query: which media kind and which locations to include.
///
/// Deliberately free of handles and sensitivity — those are resolved inside the
/// lower layers (the Data layer resolves Camera Upload handles, the Use Case
/// resolves the sensitivity preference), keeping this a pure presentation-facing
/// scope descriptor.
public struct MediaTimelineFilterEntity: Sendable, Equatable {
    public enum MediaType: Sendable, Equatable {
        case images
        case videos
        /// Photos and videos together.
        case allMedia
    }

    public enum Location: Sendable, Equatable {
        /// Cloud Drive, including the Camera Upload
        case allLocations
        /// Cloud Drive only, excluding the Camera Upload folders.
        case cloudDrive
        /// The Camera Upload folders only.
        case cameraUploads
    }

    public let mediaType: MediaType
    public let location: Location

    public init(mediaType: MediaType, location: Location) {
        self.mediaType = mediaType
        self.location = location
    }
}

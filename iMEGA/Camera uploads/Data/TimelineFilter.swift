import ContentLibraries
import Foundation

struct TimelineFilter: Equatable, Sendable {
    let filterType: PhotosFilterType
    let filterLocation: PhotosFilterLocation
    let usePreference: Bool
}

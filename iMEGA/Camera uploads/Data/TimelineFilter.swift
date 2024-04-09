import Foundation

struct TimelineFilter: Equatable {
    let filterType: PhotosFilterType
    let filterLocation: PhotosFilterLocation
    let usePreference: Bool
}

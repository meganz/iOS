import ContentLibraries
import Foundation
import MEGADomain

extension ContentConsumptionUserAttributeUseCaseProtocol {
    func fetchTimelineFilter() async -> TimelineFilter {
        let ccAttributes = await fetchTimelineAttribute()
        return TimelineFilter(
            filterType: PhotosFilterType.toFilterType(from: ccAttributes.mediaType),
            filterLocation: PhotosFilterLocation.toFilterLocation(from: ccAttributes.location),
            usePreference: ccAttributes.usePreference)
    }
}

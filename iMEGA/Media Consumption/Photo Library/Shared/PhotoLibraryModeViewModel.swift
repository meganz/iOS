import Foundation

typealias PhotoPositionId = Date?

protocol PhotoLibraryModeViewModel: ObservableObject {
    var currentScrollPositionId: PhotoPositionId { get }
    func positionId<T: PhotosChronologicalCategory>(for category: T) -> PhotoPositionId
}

extension PhotoLibraryModeViewModel {
    func positionId<T: PhotosChronologicalCategory>(for category: T) -> PhotoPositionId {
        category.categoryDate
    }
}

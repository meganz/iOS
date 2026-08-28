import Foundation
import MEGADomain

actor PhotoLibraryMapper {
    func buildPhotoLibrary(
        with nodes: [NodeEntity],
        withSortType type: SortOrderEntity,
        timestampBasis: MediaTimelineSortOrderEntity.TimestampBasis = .modificationTime
    ) -> PhotoLibrary {
        nodes.toPhotoLibrary(withSortType: type, timestampBasis: timestampBasis)
    }
}

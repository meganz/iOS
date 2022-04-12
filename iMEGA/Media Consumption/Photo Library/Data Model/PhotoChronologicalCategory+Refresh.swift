import Foundation

extension PhotoChronologicalCategory {
    static func ↻↻ (lhs: Self, rhs: Self) -> Bool {
        lhs.categoryDate != rhs.categoryDate ||
        lhs.coverPhoto != rhs.coverPhoto ||
        lhs.coverPhoto?.hasThumbnail != rhs.coverPhoto?.hasThumbnail ||
        lhs.coverPhoto?.hasPreview != rhs.coverPhoto?.hasPreview
    }
}

extension NodeEntity {
    static func ↻↻ (lhs: Self, rhs: Self) -> Bool {
        lhs.categoryDate != rhs.categoryDate ||
        lhs.coverPhoto != rhs.coverPhoto ||
        lhs.coverPhoto?.hasThumbnail != rhs.coverPhoto?.hasThumbnail ||
        lhs.isFavourite != rhs.isFavourite
    }
}

extension Array where Element: PhotoChronologicalCategory {
    func shouldRefreshTo(_ categories: [Element], forVisiblePositions positions: [PhotoScrollPosition?: Bool]) -> Bool {
        guard count == categories.count else {
            MEGALogDebug("[Photos] refresh categories \(Self.self) due to count difference")
            return true // we should refresh if the new categories has different number of elements
        }
        
        for zip in zip(self, categories) {
            guard positions[zip.0.position] == true else {
                continue // ignore invisible positions
            }
            
            if zip.0 ↻↻ zip.1 {
                MEGALogDebug("[Photos] refresh categories \(Self.self) due to refreshable is true")
                return true // we should refresh if refreshable is true
            }
        }
        
        MEGALogDebug("[Photos] don't refresh categories \(Self.self)")
        return false
    }
}

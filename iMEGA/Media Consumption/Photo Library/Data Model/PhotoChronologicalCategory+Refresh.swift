import Foundation
import MEGASwift

extension PhotoChronologicalCategory {
    public static func ↻↻ (lhs: Self, rhs: Self) -> Bool {
        lhs != rhs ||
        lhs.categoryDate != rhs.categoryDate ||
        lhs.coverPhoto?.hasThumbnail != rhs.coverPhoto?.hasThumbnail ||
        lhs.coverPhoto?.hasPreview != rhs.coverPhoto?.hasPreview ||
        lhs.coverPhoto?.isFavourite != rhs.coverPhoto?.isFavourite
    }
}

extension Array where Element: PhotoChronologicalCategory {
    func shouldRefresh(to categories: [Element], visiblePositions: [PhotoScrollPosition?: Bool] = [:]) -> Bool {
        guard count == categories.count else {
            MEGALogDebug("[Photos] refresh categories \(Self.self) due to count difference")
            return true
        }
        
        for zip in zip(self, categories) {
            if visiblePositions[zip.0.position] == true && zip.0 ↻↻ zip.1 {
                MEGALogDebug("[Photos] refresh categories \(Self.self) due to refreshable is true")
                return true
            }
            
            if zip.0 == zip.1 {
                continue
            } else {
                return true
            }
        }
        
        MEGALogDebug("[Photos] don't refresh categories \(Self.self)")
        return false
    }
}

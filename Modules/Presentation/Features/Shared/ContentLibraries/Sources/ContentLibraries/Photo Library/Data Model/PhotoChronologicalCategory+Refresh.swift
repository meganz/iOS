import Foundation
import MEGASwift

extension PhotoChronologicalCategory {
    public static func ↻↻ (lhs: Self, rhs: Self) -> Bool {
        lhs.categoryDate != rhs.categoryDate ||
        lhs.coverPhoto != rhs.coverPhoto
    }
    
    public static func ↻↻⏿ (lhs: Self, rhs: Self) -> Bool {
        lhs.categoryDate != rhs.categoryDate ||
        lhs.coverPhoto != rhs.coverPhoto ||
        lhs.coverPhoto?.hasThumbnail != rhs.coverPhoto?.hasThumbnail ||
        lhs.coverPhoto?.hasPreview != rhs.coverPhoto?.hasPreview ||
        lhs.coverPhoto?.isFavourite != rhs.coverPhoto?.isFavourite ||
        lhs.coverPhoto?.isMarkedSensitive != rhs.coverPhoto?.isMarkedSensitive
    }
}

extension Array where Element: PhotoChronologicalCategory {
    func shouldRefresh(to categories: [Element], visiblePositions: [PhotoScrollPosition?: Bool] = [:]) -> Bool {
        guard count == categories.count else { return true }
        
        for zip in zip(self, categories) {
            if visiblePositions[zip.0.position] == true {
                if zip.0 ↻↻⏿ zip.1 {
                    return true
                }
            } else {
                if zip.0 ↻↻ zip.1 {
                    return true
                }
            }
        }
        
        return false
    }
}

extension Array where Element: PhotoSection {
    func shouldRefresh(to categories: [Element], visiblePositions: [PhotoScrollPosition?: Bool] = [:]) -> Bool {
        guard count == categories.count else { return true }
        for zip in zip(self, categories) {
            guard zip.0.title == zip.1.title, zip.0.categoryDate == zip.1.categoryDate else {
                return true
            }
            
            if zip.0.contentList.shouldRefresh(to: zip.1.contentList, visiblePositions: visiblePositions) {
                return true
            }
        }
        
        return false
    }
}

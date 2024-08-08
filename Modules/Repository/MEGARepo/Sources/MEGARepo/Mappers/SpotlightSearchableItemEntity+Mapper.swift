import CoreSpotlight
import Foundation
import MEGADomain

extension SpotlightSearchableItemEntity {
    func toCSSearchableItem() -> CSSearchableItem {
        CSSearchableItem(
            uniqueIdentifier: uniqueIdentifier,
            domainIdentifier: domainIdentifier,
            attributeSet: toCSSearchableItemAttributeSet())
    }
    
    fileprivate func toCSSearchableItemAttributeSet() -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(contentType: contentType)
        attributeSet.title = title
        attributeSet.contentDescription = contentDescription
        attributeSet.thumbnailData = thumbnailData
        return attributeSet
    }
}

import Foundation
import MEGADomain
import MEGASwift

protocol PhotoChronologicalCategory: Identifiable, Equatable, Refreshable, RefreshableWhenVisible {
    associatedtype Content: PhotoChronologicalCategory
    var contentList: [Content] { get }
    
    var categoryDate: Date { get }
    var coverPhoto: NodeEntity? { get }
}

extension PhotoChronologicalCategory {
    var position: PhotoScrollPosition? {
        guard let photo = coverPhoto else {
            return nil
        }
        
        return PhotoScrollPosition(handle: photo.handle, date: photo.categoryDate)
    }
    
    var id: PhotoScrollPosition? {
        position
    }
    
    var coverPhoto: NodeEntity? {
        contentList.first?.coverPhoto
    }
}

extension PhotoChronologicalCategory {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.contentList == rhs.contentList && lhs.categoryDate == rhs.categoryDate
    }
}

struct PhotoByYear: PhotoChronologicalCategory {
    let categoryDate: Date
    let contentList: [PhotoByMonth]
}

struct PhotoByMonth: PhotoChronologicalCategory {
    let categoryDate: Date
    let contentList: [PhotoByDay]
    
    var allPhotos: [NodeEntity] {
        contentList.flatMap { $0.contentList }
    }
}

struct PhotoByDay: PhotoChronologicalCategory {
    let categoryDate: Date
    let contentList: [NodeEntity]
}

extension NodeEntity: PhotoChronologicalCategory {
    var categoryDate: Date {
        modificationTime
    }
    
    var coverPhoto: NodeEntity? {
        self
    }
    
    var contentList: [NodeEntity] {
        [self]
    }
}

import Foundation
import MEGADomain
import MEGASwift

public protocol PhotoChronologicalCategory: Identifiable, Equatable, Refreshable, RefreshableWhenVisible {
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
    
    public var id: PhotoScrollPosition? {
        position
    }
    
    public var coverPhoto: NodeEntity? {
        contentList.first?.coverPhoto
    }
}

extension PhotoChronologicalCategory {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.contentList == rhs.contentList && lhs.categoryDate == rhs.categoryDate
    }
}

public struct PhotoByYear: PhotoChronologicalCategory, Sendable {
    public let categoryDate: Date
    public let contentList: [PhotoByMonth]
}

public struct PhotoByMonth: PhotoChronologicalCategory, Sendable {
    public let categoryDate: Date
    public let contentList: [PhotoByDay]
    
    var allPhotos: [NodeEntity] {
        contentList.flatMap { $0.contentList }
    }
}

public struct PhotoByDay: PhotoChronologicalCategory, Sendable {
    public let categoryDate: Date
    public let contentList: [NodeEntity]
}

extension NodeEntity: @retroactive RefreshableWhenVisible {}
extension NodeEntity: @retroactive Refreshable {}

extension NodeEntity: PhotoChronologicalCategory {
    public var categoryDate: Date {
        modificationTime
    }
    
    public var coverPhoto: NodeEntity? {
        self
    }
    
    public var contentList: [NodeEntity] {
        [self]
    }
}

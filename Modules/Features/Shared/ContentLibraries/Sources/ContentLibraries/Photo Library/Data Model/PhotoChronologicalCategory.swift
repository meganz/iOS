import Foundation
import MEGADomain
import MEGASwift

public protocol PhotoChronologicalCategory: Identifiable, Equatable, Refreshable, RefreshableWhenVisible {
    associatedtype Content: PhotoChronologicalCategory
    var contentList: [Content] { get }
    
    var categoryDate: Date { get }
    var coverPhoto: NodeEntity? { get }

    /// `categoryDate` of the day bucket the cover photo sits in — the date every scroll position
    /// is expressed in, because that is what `indexPath(of:)` and the card views match on. It is
    /// resolved down the tree rather than taken from the cover node's own `categoryDate`: on the
    /// paginated timeline the buckets come from the SDK's `groupId`s, so a node's modification
    /// time frequently lands on another day than the bucket rendering it — and when the timeline
    /// is ordered by media capture time, on another timestamp column entirely.
    var coverDayDate: Date? { get }
}

extension PhotoChronologicalCategory {
    /// Year and month levels inherit the day of their first descendant; the day level and the
    /// leaf node override this.
    public var coverDayDate: Date? {
        contentList.first?.coverDayDate
    }

    var position: PhotoScrollPosition? {
        guard let photo = coverPhoto, let coverDayDate else {
            return nil
        }
        
        return PhotoScrollPosition(handle: photo.handle, date: coverDayDate)
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
    
    public init(categoryDate: Date, contentList: [PhotoByMonth]) {
        self.categoryDate = categoryDate
        self.contentList = contentList
    }
}

public struct PhotoByMonth: PhotoChronologicalCategory, Sendable {
    public let categoryDate: Date
    public let contentList: [PhotoByDay]
    
    public init(categoryDate: Date, contentList: [PhotoByDay]) {
        self.categoryDate = categoryDate
        self.contentList = contentList
    }
    
    var allPhotos: [NodeEntity] {
        contentList.flatMap { $0.contentList }
    }
}

public struct PhotoByDay: PhotoChronologicalCategory, Sendable {
    public let categoryDate: Date
    public let contentList: [NodeEntity]
    
    public init(categoryDate: Date, contentList: [NodeEntity]) {
        self.categoryDate = categoryDate
        self.contentList = contentList
    }

    /// The day bucket is this category, so the recursion stops here rather than falling through
    /// to a leaf node's own timestamp.
    public var coverDayDate: Date? { categoryDate }
}

extension NodeEntity: @retroactive RefreshableWhenVisible {}
extension NodeEntity: @retroactive Refreshable {}

extension NodeEntity: PhotoChronologicalCategory {
    public var categoryDate: Date {
        modificationTime
    }

    /// A node knows nothing about the bucket rendering it, so it can only answer with its own
    /// date. Every caller that has a tree resolves the day from the enclosing `PhotoByDay`.
    public var coverDayDate: Date? { categoryDate }
    
    public var coverPhoto: NodeEntity? {
        self
    }
    
    public var contentList: [NodeEntity] {
        [self]
    }
}

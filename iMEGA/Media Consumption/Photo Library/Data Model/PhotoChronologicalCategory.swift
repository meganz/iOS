import Foundation

protocol PhotoChronologicalCategory: Identifiable, PhotoScrollPositioning, Refreshable, Equatable {
    associatedtype Content: Equatable
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
}

extension PhotoChronologicalCategory {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.contentList == rhs.contentList
    }
}

struct PhotoByYear: PhotoChronologicalCategory {
    let categoryDate: Date
    private(set) var contentList = [PhotoByMonth]()
    
    var coverPhoto: NodeEntity? {
        contentList.first?.coverPhoto
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
    
    mutating func append(_ photoByMonth: PhotoByMonth) {
        contentList.append(photoByMonth)
    }
}

struct PhotoByMonth: PhotoChronologicalCategory {
    let categoryDate: Date
    private(set) var contentList = [PhotoByDay]()
    
    var allPhotos: [NodeEntity] {
        contentList.flatMap { $0.contentList }
    }
    
    var coverPhoto: NodeEntity? {
        contentList.first?.coverPhoto
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
    
    mutating func append(_ photoByDay: PhotoByDay) {
        contentList.append(photoByDay)
    }
}

struct PhotoByDay: PhotoChronologicalCategory {
    let categoryDate: Date
    private(set) var contentList = [NodeEntity]()
    
    var coverPhoto: NodeEntity? {
        contentList.first
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
    
    mutating func append(_ photo: NodeEntity) {
        contentList.append(photo)
    }
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

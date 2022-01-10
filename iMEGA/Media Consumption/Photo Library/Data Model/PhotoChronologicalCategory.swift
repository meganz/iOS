import Foundation

protocol PhotoChronologicalCategory: Identifiable, PhotoScrollPositioning, Refreshable {
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

struct PhotoByYear: PhotoChronologicalCategory {
    let categoryDate: Date
    private(set) var photoByMonthList = [PhotoByMonth]()
    
    var coverPhoto: NodeEntity? {
        photoByMonthList.first?.coverPhoto
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
    
    mutating func append(_ photoByMonth: PhotoByMonth) {
        photoByMonthList.append(photoByMonth)
    }
}

extension PhotoByYear: Equatable {
    static func == (lhs: PhotoByYear, rhs: PhotoByYear) -> Bool {
        lhs.photoByMonthList == rhs.photoByMonthList
    }
}

struct PhotoByMonth: PhotoChronologicalCategory {
    let categoryDate: Date
    private(set) var photoByDayList = [PhotoByDay]()
    
    var allPhotos: [NodeEntity] {
        photoByDayList.flatMap { $0.photoNodeList }
    }
    
    var coverPhoto: NodeEntity? {
        photoByDayList.first?.coverPhoto
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
    
    mutating func append(_ photoByDay: PhotoByDay) {
        photoByDayList.append(photoByDay)
    }
}

extension PhotoByMonth: Equatable {
    static func == (lhs: PhotoByMonth, rhs: PhotoByMonth) -> Bool {
        lhs.photoByDayList == rhs.photoByDayList
    }
}

struct PhotoByDay: PhotoChronologicalCategory {
    let categoryDate: Date
    private(set) var photoNodeList = [NodeEntity]()
    
    var coverPhoto: NodeEntity? {
        photoNodeList.first
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
    
    mutating func append(_ photo: NodeEntity) {
        photoNodeList.append(photo)
    }
}

extension PhotoByDay: Equatable {
    static func == (lhs: PhotoByDay, rhs: PhotoByDay) -> Bool {
        lhs.photoNodeList == rhs.photoNodeList
    }
}

extension NodeEntity: PhotoChronologicalCategory {
    var categoryDate: Date {
        modificationTime
    }
    
    var coverPhoto: NodeEntity? {
        self
    }
}

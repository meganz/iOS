import Foundation

protocol PhotosChronologicalCategory: Identifiable, ScrollPositioning {
    var categoryDate: Date { get }
    var coverPhoto: NodeEntity? { get }
}

extension PhotosChronologicalCategory {
    var position: PhotoScrollPosition {
        coverPhoto?.handle
    }
}

final class PhotosByYear: PhotosChronologicalCategory {
    let categoryDate: Date
    var photosByMonthList = [PhotosByMonth]()
    
    var coverPhoto: NodeEntity? {
        photosByMonthList.first?.coverPhoto
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
}

final class PhotosByMonth: PhotosChronologicalCategory {
    let categoryDate: Date
    var photosByDayList = [PhotosByDay]()
    
    var allPhotos: [NodeEntity] {
        photosByDayList.flatMap { $0.photoNodeList }
    }
    
    var coverPhoto: NodeEntity? {
        photosByDayList.first?.coverPhoto
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
}

final class PhotosByDay: PhotosChronologicalCategory {
    let categoryDate: Date
    var photoNodeList = [NodeEntity]()
    
    var coverPhoto: NodeEntity? {
        photoNodeList.first
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
}

extension NodeEntity: PhotosChronologicalCategory {
    var categoryDate: Date {
        modificationTime
    }
    
    var coverPhoto: NodeEntity? {
        self
    }
}

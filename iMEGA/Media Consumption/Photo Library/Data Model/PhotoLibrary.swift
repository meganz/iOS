import Foundation
import PinLayout
import SwiftUI

final class PhotoLibrary {
    var photosByYearList: [PhotosByYear]
    var underlyingMEGANodes: [MEGANode]
    
    var allPhotosByMonthList: [PhotosByMonth] {
        photosByYearList.flatMap { $0.photosByMonthList }
    }
    
    var allPhotosByDayList: [PhotosByDay] {
        allPhotosByMonthList.flatMap { $0.photosByDayList }
    }
    
    var allPhotos: [NodeEntity] {
        allPhotosByDayList.flatMap { $0.photoNodeList }
    }
    
    var isEmpty: Bool {
        photosByYearList.isEmpty
    }
    
    init(photosByYearList: [PhotosByYear], underlyingMEGANodes: [MEGANode] = []) {
        self.photosByYearList = photosByYearList
        self.underlyingMEGANodes = underlyingMEGANodes
    }
}

protocol PhotosChronologicalCategory: Identifiable {
    var categoryDate: Date { get }
    var coverPhoto: NodeEntity? { get }
}

final class PhotosByYear: PhotosChronologicalCategory {
    let categoryDate: Date
    var photosByMonthList = [PhotosByMonth]()
    
    var coverPhoto: NodeEntity? {
        photosByMonthList.last?.coverPhoto
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
        photosByDayList.last?.coverPhoto
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
}

final class PhotosByDay: PhotosChronologicalCategory {
    let categoryDate: Date
    var photoNodeList = [NodeEntity]()
    
    var coverPhoto: NodeEntity? {
        photoNodeList.last
    }
    
    init(categoryDate: Date) {
        self.categoryDate = categoryDate
    }
}

extension NodeEntity: PhotosChronologicalCategory {
    var categoryDate: Date {
        createTime ?? Date()
    }
    
    var coverPhoto: NodeEntity? {
        self
    }
}

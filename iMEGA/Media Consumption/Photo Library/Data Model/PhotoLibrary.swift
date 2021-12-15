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

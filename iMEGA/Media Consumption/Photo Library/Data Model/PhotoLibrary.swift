import Foundation
import PinLayout
import SwiftUI

final class PhotoLibrary {
    var allphotosByYearList: [PhotosByYear]
    var underlyingMEGANodes: [MEGANode]
    
    var allPhotosByMonthList: [PhotosByMonth] {
        allphotosByYearList.flatMap { $0.photosByMonthList }
    }
    
    var allPhotosByDayList: [PhotosByDay] {
        allPhotosByMonthList.flatMap { $0.photosByDayList }
    }
    
    var allPhotos: [NodeEntity] {
        allPhotosByDayList.flatMap { $0.photoNodeList }
    }
    
    var isEmpty: Bool {
        allphotosByYearList.isEmpty
    }
    
    init(photosByYearList: [PhotosByYear] = [], underlyingMEGANodes: [MEGANode] = []) {
        self.allphotosByYearList = photosByYearList
        self.underlyingMEGANodes = underlyingMEGANodes
    }
}

import Foundation
import PinLayout
import SwiftUI

struct PhotoLibrary {
    let allphotoByYearList: [PhotoByYear]
    var underlyingMEGANodes: [MEGANode]
    
    var allPhotosByMonthList: [PhotoByMonth] {
        allphotoByYearList.flatMap { $0.photoByMonthList }
    }
    
    var allPhotosByDayList: [PhotoByDay] {
        allPhotosByMonthList.flatMap { $0.photoByDayList }
    }
    
    var allPhotos: [NodeEntity] {
        allPhotosByDayList.flatMap { $0.photoNodeList }
    }
    
    var isEmpty: Bool {
        allphotoByYearList.isEmpty
    }
    
    init(photoByYearList: [PhotoByYear] = [], underlyingMEGANodes: [MEGANode] = []) {
        self.allphotoByYearList = photoByYearList
        self.underlyingMEGANodes = underlyingMEGANodes
    }
}

extension PhotoLibrary: Equatable {
    static func == (lhs: PhotoLibrary, rhs: PhotoLibrary) -> Bool {
        lhs.allphotoByYearList == rhs.allphotoByYearList
    }
}

extension PhotoLibrary {
    func allPhotosDateSections(forZoomScaleFactor scaleFactor: Int?) -> [PhotoDateSection] {
        guard let factor = scaleFactor else { return [] }
        
        return factor == 1 ? allPhotosDaySections : allPhotosMonthSections
    }
}

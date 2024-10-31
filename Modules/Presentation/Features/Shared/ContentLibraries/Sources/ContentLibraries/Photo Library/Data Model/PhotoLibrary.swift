import Foundation
import MEGADomain
import SwiftUI

public struct PhotoLibrary: Sendable {
    let photoByYearList: [PhotoByYear]
    
    var photosByMonthList: [PhotoByMonth] {
        photoByYearList.flatMap { $0.contentList }
    }
    
    var photosByDayList: [PhotoByDay] {
        photosByMonthList.flatMap { $0.contentList }
    }
    
    public var allPhotos: [NodeEntity] {
        photosByDayList.flatMap { $0.contentList }
    }
    
    public var isEmpty: Bool {
        photoByYearList.isEmpty
    }
    
    public init(photoByYearList: [PhotoByYear] = []) {
        self.photoByYearList = photoByYearList
    }
}

extension PhotoLibrary: Equatable {
    static public func == (lhs: PhotoLibrary, rhs: PhotoLibrary) -> Bool {
        lhs.photoByYearList == rhs.photoByYearList
    }
}

extension PhotoLibrary {
    func photoDateSections(for factor: PhotoLibraryZoomState.ScaleFactor) -> [PhotoDateSection] {
        factor == .one ? photoDaySections : photoMonthSections
    }
}

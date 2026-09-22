import Foundation
import MEGADomain
import SwiftUI

public struct PhotoLibrary: Sendable {
    /// What a library that is never re-laid out carries — every screen but the paginated timeline.
    public static let initialLayoutVersion = 0

    let photoByYearList: [PhotoByYear]

    /// Identifies the layout this library describes, so a position read off the screen can be
    /// checked against it. It moves when the meaning of a position changes — a different query, or
    /// buckets added, removed, reordered or resized — and stays put when only a slot's contents do.
    public let layoutVersion: Int
    
    var photosByMonthList: [PhotoByMonth] {
        photoByYearList.flatMap { $0.contentList }
    }
    
    /// The day buckets in flat display order. Public because the timeline addresses a slot by the
    /// bucket holding it rather than by an absolute position, and reads the tree one bucket at a
    /// time instead of flattening it.
    public var photosByDayList: [PhotoByDay] {
        photosByMonthList.flatMap { $0.contentList }
    }
    
    public var allPhotos: [NodeEntity] {
        photosByDayList.flatMap { $0.contentList }
    }
    
    public var isEmpty: Bool {
        photoByYearList.isEmpty
    }
    
    public init(
        photoByYearList: [PhotoByYear] = [],
        layoutVersion: Int = PhotoLibrary.initialLayoutVersion
    ) {
        self.photoByYearList = photoByYearList
        self.layoutVersion = layoutVersion
    }
}

public extension PhotoLibrary {
    /// The same photos, stamped as a new layout. See ``layoutVersion``.
    func withLayoutVersion(_ layoutVersion: Int) -> PhotoLibrary {
        PhotoLibrary(photoByYearList: photoByYearList, layoutVersion: layoutVersion)
    }
}

extension PhotoLibrary: Equatable {
    static public func == (lhs: PhotoLibrary, rhs: PhotoLibrary) -> Bool {
        lhs.layoutVersion == rhs.layoutVersion && lhs.photoByYearList == rhs.photoByYearList
    }
}

extension PhotoLibrary {
    func photoDateSections(for factor: PhotoLibraryZoomState.ScaleFactor) -> [PhotoDateSection] {
        factor == .one ? photoDaySections : photoMonthSections
    }

    var photoMasonrySection: PhotoDateSection {
        PhotoDateSection(
            photoByDayList: photosByDayList,
            categoryDate: photoByYearList.first?.categoryDate ?? Date(),
            layoutVersion: layoutVersion
        )
    }
}

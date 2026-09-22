@testable import ContentLibraries
import Foundation
import MEGADomain
import Testing

/// The layout version travels with the data it describes — library → sections → grid — never on a
/// path of its own: the grid renders a debounce behind, so a version out of step with its sections
/// would be worse than none. These tests say the two cannot come apart.
@Suite("Photo library layout version")
struct PhotoLibraryLayoutVersionTests {

    /// Two day buckets in one month, counts 2 and 3.
    private static func makeLibrary(layoutVersion: Int) -> PhotoLibrary {
        let day1 = Date(timeIntervalSince1970: 1_660_780_800) // 2022-08-18T00:00:00Z
        let day2 = Date(timeIntervalSince1970: 1_660_694_400) // 2022-08-17T00:00:00Z
        return PhotoLibrary.skeleton(from: [
            MediaDateSectionEntity(groupId: "2022-08-18", startDate: day1, endDate: day1, count: 2),
            MediaDateSectionEntity(groupId: "2022-08-17", startDate: day2, endDate: day2, count: 3)
        ])
        .withLayoutVersion(layoutVersion)
    }

    @Test("A library nobody stamps stays on the initial version")
    func defaultsToInitialVersion() {
        #expect(PhotoLibrary().layoutVersion == PhotoLibrary.initialLayoutVersion)
        #expect(Self.makeLibrary(layoutVersion: PhotoLibrary.initialLayoutVersion).layoutVersion
            == PhotoLibrary.initialLayoutVersion)
    }

    @Test("Every rendering of a library carries its version, at either grouping")
    func sectionsCarryTheVersion() {
        let library = Self.makeLibrary(layoutVersion: 7)

        #expect(library.photoDaySections.map(\.layoutVersion) == [7, 7])
        #expect(library.photoMonthSections.map(\.layoutVersion) == [7])
        #expect(library.photoMasonrySection.layoutVersion == 7)
        #expect(library.photoDateSections(for: .one).map(\.layoutVersion) == [7, 7])
        #expect(library.photoDateSections(for: .three).map(\.layoutVersion) == [7])
    }

    @Test("The grid reads one version for the sections it is showing")
    func renderedSectionsAnswerWithOneVersion() {
        let sections = Self.makeLibrary(layoutVersion: 7).photoDaySections

        #expect(sections.layoutVersion == 7)
        // Nothing is on screen to interact with, so nothing asks about this one.
        #expect([PhotoDaySection]().layoutVersion == PhotoLibrary.initialLayoutVersion)
    }

    @Test("Filling slots leaves the layout where it was — a splice fills positions, it never moves them")
    func hydrationPreservesTheVersion() {
        let library = Self.makeLibrary(layoutVersion: 7)

        let hydrated = library.replacingPhotos(from: 0, with: [NodeEntity(handle: 10)])

        #expect(hydrated.layoutVersion == 7)
        #expect(hydrated.photoDaySections.map(\.layoutVersion) == [7, 7])
        #expect(hydrated.allPhotos[0].handle == 10) // the splice did happen
    }

    @Test("Two libraries holding the same photos in different layouts are not the same library")
    func versionParticipatesInEquality() {
        #expect(Self.makeLibrary(layoutVersion: 7) != Self.makeLibrary(layoutVersion: 8))
        #expect(Self.makeLibrary(layoutVersion: 7) == Self.makeLibrary(layoutVersion: 7))
    }
}

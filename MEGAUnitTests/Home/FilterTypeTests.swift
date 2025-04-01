@testable import MEGA
import MEGAL10n
import XCTest

final class FilterTypeTests: XCTestCase {
    func testLocalisation_localizedStringIsAllMedia() {
        let expectedAllMediaValue = Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.allMedia
        let localizedAllMediaValue = FilterType.allMedia.localizedString
        XCTAssertEqual(expectedAllMediaValue, localizedAllMediaValue, "Localized string for 'allMedia' should be \(expectedAllMediaValue)")
    }

    func testLocalisation_localizedStringIsImages() {
        let expectedImagesValue = Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.images
        let localizedImagesValue = FilterType.images.localizedString
        XCTAssertEqual(expectedImagesValue, localizedImagesValue, "Localized string for 'images' should be \(expectedImagesValue)")
    }

    func testLocalisation_localizedStringIsVideos() {
        let expectedVideosValue = Strings.Localizable.CameraUploads.Timeline.Filter.MediaType.videos
        let localizedVideosValue = FilterType.videos.localizedString
        XCTAssertEqual(expectedVideosValue, localizedVideosValue, "Localized string for 'videos' should be \(expectedVideosValue)")
    }

    func testLocalisation_EmptyStringIsNoneCase() {
        let expectedNoneValue = ""
        let localizedNoneValue = FilterType.none.localizedString
        XCTAssertEqual(expectedNoneValue, localizedNoneValue, "Localized string for 'none' should be \(expectedNoneValue)")
    }
}

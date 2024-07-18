@testable import MEGA
import MEGADomain
import MEGAPresentation
import SwiftUI
import XCTest

final class Preview_ThumbnailLoaderTests: XCTestCase {
    private var sut: Preview_ThumbnailLoader!

    override func setUp() {
        super.setUp()
        sut = Preview_ThumbnailLoader()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testPreviewThumbnailLoader_onInitialImage_returnsImagContainerType() {
        let node = makeMockNodeEntity()
        let type = makeMockThumbnailType()

        let result = sut.initialImage(for: node, type: type)

        XCTAssertTrue(result is ImageContainer)
    }

    func testPreviewThumbnailLoader_onInitialImage_returnsImageFolder() {
        let node = makeMockNodeEntity()
        let type = makeMockThumbnailType()

        let result = sut.initialImage(for: node, type: type)

        XCTAssertEqual(result.image, Image("folder"))
    }

    func testPreviewThumbnailLoader_onInitialImage__returnsTypeThumbnail() {
        let node = makeMockNodeEntity()
        let type = makeMockThumbnailType()

        let result = sut.initialImage(for: node, type: type)

        XCTAssertEqual(result.type, .thumbnail)
    }

    func testPreviewThumbnailLoader_onInitialImageWithPlaceholder_returnsImageContainer() {
        let node = makeMockNodeEntity()
        let type = makeMockThumbnailType()

        let placeholder = makeMockPlaceHolder()

        let result = sut.initialImage(for: node, type: type, placeholder: placeholder)

        XCTAssertTrue(result is ImageContainer)
    }

    func testPreviewThumbnailLoader_onInitialImageWithPlaceholder_returnsImageFolder() {
        let node = makeMockNodeEntity()
        let type = makeMockThumbnailType()

        let placeholder = makeMockPlaceHolder()

        let result = sut.initialImage(for: node, type: type, placeholder: placeholder)

        XCTAssertEqual(result.image, Image("folder"))
    }

    func testPreviewThumbnailLoader_onInitialImageWithPlaceholder_returnsThumbnailType() {
        let node = makeMockNodeEntity()
        let type = makeMockThumbnailType()

        let placeholder = makeMockPlaceHolder()

        let result = sut.initialImage(for: node, type: type, placeholder: placeholder)

        XCTAssertTrue(result is ImageContainer)
        XCTAssertEqual(result.image, Image("folder"))
        XCTAssertEqual(result.type, .thumbnail)
    }

    // MARK: Mocks
    private func makeMockNodeEntity() -> NodeEntity {
        NodeEntity()
    }

    private func makeMockThumbnailType() -> ThumbnailTypeEntity {
        .thumbnail
    }

    private func makeMockPlaceHolder() -> @Sendable () -> Image {
        let placeHolder: @Sendable () -> Image = {
            Image("placeholder")
        }

        return placeHolder
    }
}

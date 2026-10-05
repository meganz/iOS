import Foundation
@testable import MEGAPDFViewer
import PDFKit
import Testing
import UIKit

@MainActor
struct PDFThumbnailLoaderTests {

    @Test func zeroSize_returnsNil() async {
        let sut = makeSUT()

        let thumbnail = await sut.thumbnail(
            forPageAt: 0, size: .zero, displayScale: 3
        )

        #expect(thumbnail == nil)
    }

    @Test func outOfRangePageIndex_returnsNil() async {
        let sut = makeSUT(pageCount: 2)

        let thumbnail = await sut.thumbnail(
            forPageAt: 2, size: thumbnailSize, displayScale: 3
        )

        #expect(thumbnail == nil)
    }

    @Test func rendersWithinRequestedPixelBox() async throws {
        let sut = makeSUT()

        let thumbnail = try #require(await sut.thumbnail(
            forPageAt: 0, size: thumbnailSize, displayScale: 3
        ))

        let cgImage = try #require(thumbnail.cgImage)
        #expect(cgImage.width <= Int(thumbnailSize.width * 3))
        #expect(cgImage.height <= Int(thumbnailSize.height * 3))
    }

    /// The pixel size is the point size times the display scale, so a page
    /// rendered at @3x is three times the size of the same page at @1x.
    @Test func pixelSizeScalesWithDisplayScale() async throws {
        let sut = makeSUT()

        let atOne = try #require(await sut.thumbnail(
            forPageAt: 0, size: thumbnailSize, displayScale: 1
        )?.cgImage)
        let atThree = try #require(await sut.thumbnail(
            forPageAt: 0, size: thumbnailSize, displayScale: 3
        )?.cgImage)

        #expect(abs(atThree.width - atOne.width * 3) <= 1)
        #expect(abs(atThree.height - atOne.height * 3) <= 1)
    }

    @Test func repeatedRequest_returnsTheCachedInstance() async throws {
        let sut = makeSUT()

        let first = try #require(await sut.thumbnail(
            forPageAt: 0, size: thumbnailSize, displayScale: 3
        ))
        let second = try #require(await sut.thumbnail(
            forPageAt: 0, size: thumbnailSize, displayScale: 3
        ))

        #expect(first === second)
    }

    /// The legacy cache keyed on page index alone, so it served a stale size
    /// after a rotation. Scale and size are both part of the key.
    @Test func differentDisplayScale_rendersSeparately() async throws {
        let sut = makeSUT()

        let atTwo = try #require(await sut.thumbnail(
            forPageAt: 0, size: thumbnailSize, displayScale: 2
        ))
        let atThree = try #require(await sut.thumbnail(
            forPageAt: 0, size: thumbnailSize, displayScale: 3
        ))

        #expect(atTwo !== atThree)
    }

    @Test func differentSize_rendersSeparately() async throws {
        let sut = makeSUT()

        let narrow = try #require(await sut.thumbnail(
            forPageAt: 0, size: thumbnailSize, displayScale: 3
        ))
        let wide = try #require(await sut.thumbnail(
            forPageAt: 0,
            size: CGSize(width: thumbnailSize.width * 2, height: thumbnailSize.height * 2),
            displayScale: 3
        ))

        #expect(narrow !== wide)
    }

    /// `PDFPage.thumbnail` serialises per page rather than per document, so a
    /// grid, which never asks for one page twice, does not contend.
    @Test func concurrentDistinctPages_allSucceed() async {
        let pageCount = 32
        let sut = makeSUT(pageCount: pageCount)

        let rendered = await withTaskGroup(of: Bool.self) { group in
            for page in 0..<pageCount {
                let size = thumbnailSize
                group.addTask {
                    await sut.thumbnail(
                        forPageAt: page, size: size, displayScale: 3
                    ) != nil
                }
            }
            var count = 0
            for await success in group where success { count += 1 }
            return count
        }

        #expect(rendered == pageCount)
    }

    @Test func concurrentSamePage_allSucceed() async {
        let requests = 32
        let sut = makeSUT()

        let rendered = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<requests {
                let size = thumbnailSize
                group.addTask {
                    await sut.thumbnail(
                        forPageAt: 0, size: size, displayScale: 3
                    ) != nil
                }
            }
            var count = 0
            for await success in group where success { count += 1 }
            return count
        }

        #expect(rendered == requests)
    }

    // MARK: - Helpers

    private var thumbnailSize: CGSize { CGSize(width: 123, height: 168) }

    private func makeSUT(pageCount: Int = 1) -> PDFThumbnailLoader {
        PDFThumbnailLoader(document: makeDocument(pageCount: pageCount))
    }

    private func makeDocument(pageCount: Int) -> PDFDocument {
        let document = PDFDocument()
        for index in 0..<pageCount {
            document.insert(PDFPage(), at: index)
        }
        return document
    }
}

@testable import ContinueWhereYouLeftOff
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGADomainMock
import SwiftUI
import Testing
import UIKit

@Suite("LeftOffItemCardViewModel")
@MainActor
struct LeftOffItemCardViewModelTests {
    private func makeNode(hasThumbnail: Bool) -> NodeEntity {
        NodeEntity(name: "photo.jpg", handle: 1, hasThumbnail: hasThumbnail)
    }

    private func makeSUT(thumbnailUseCase: MockThumbnailUseCase = MockThumbnailUseCase()) -> LeftOffItemCardViewModel {
        LeftOffItemCardViewModel(
            thumbnailLoader: ThumbnailLoaderFactory.makeThumbnailLoader(config: .general, thumbnailUseCase: thumbnailUseCase)
        )
    }

    private func writeTemporaryImage() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).png")
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4))
        try renderer.pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }.write(to: url)
        return url
    }

    @Test("a card starts without a thumbnail")
    func startsWithoutThumbnail() {
        let sut = makeSUT()

        #expect(sut.thumbnailLoaded == false)
    }

    @Test("a card without a thumbnail never loads one")
    func noThumbnailKeepsPlaceholder() async throws {
        let url = try writeTemporaryImage()
        defer { try? FileManager.default.removeItem(at: url) }
        let sut = makeSUT(
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(ThumbnailEntity(url: url, type: .thumbnail)))
        )

        await sut.loadThumbnail(for: makeNode(hasThumbnail: false))

        #expect(sut.thumbnailLoaded == false)
    }

    @Test("a card with a thumbnail loads it")
    func cardWithThumbnailLoadsIt() async throws {
        let url = try writeTemporaryImage()
        defer { try? FileManager.default.removeItem(at: url) }
        let sut = makeSUT(
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(ThumbnailEntity(url: url, type: .thumbnail)))
        )

        await sut.loadThumbnail(for: makeNode(hasThumbnail: true))

        #expect(sut.thumbnailLoaded)
    }

    @Test("a node that gains a thumbnail later loads it")
    func nodeGainingThumbnailLoadsIt() async throws {
        let url = try writeTemporaryImage()
        defer { try? FileManager.default.removeItem(at: url) }
        let sut = makeSUT(
            thumbnailUseCase: MockThumbnailUseCase(loadThumbnailResult: .success(ThumbnailEntity(url: url, type: .thumbnail)))
        )

        await sut.loadThumbnail(for: makeNode(hasThumbnail: false))
        #expect(sut.thumbnailLoaded == false)
        await sut.loadThumbnail(for: makeNode(hasThumbnail: true))

        #expect(sut.thumbnailLoaded)
    }

    @Test("a failed thumbnail load keeps the file type icon")
    func failedLoadKeepsPlaceholder() async {
        let sut = makeSUT()

        await sut.loadThumbnail(for: makeNode(hasThumbnail: true))

        #expect(sut.thumbnailLoaded == false)
    }

    @Test("files with the same extension get the same icon")
    func sameExtensionGivesSameIcon() {
        let sut = makeSUT()

        #expect(sut.fileTypeIcon(for: "notes.txt") == sut.fileTypeIcon(for: "todo.txt"))
    }

    @Test("a different extension gives a different icon")
    func differentExtensionGivesDifferentIcon() {
        let sut = makeSUT()

        #expect(sut.fileTypeIcon(for: "notes.txt") != sut.fileTypeIcon(for: "notes.pdf"))
    }
}

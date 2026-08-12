import FileLink
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGASwift
import SwiftUI
import Testing

@Suite("FileLinkContentViewModel Tests")
@MainActor
struct FileLinkContentViewModelTests {
    @Test("a file starts on its file type icon")
    func preview_beforeLoading_isFileTypeIcon() {
        let sut = makeSUT(node: NodeEntity(name: "elcapitan.jpeg", hasPreview: true))

        #expect(isFileTypeIcon(sut.preview))
    }

    @Test("an image shows the loaded preview with no video decoration")
    func loadPreview_image_showsMediaWithoutDuration() async {
        let sut = makeSUT(
            node: NodeEntity(name: "elcapitan.jpeg", hasPreview: true),
            loadedPreview: .init(image: Image(systemName: "photo"), type: .preview)
        )

        await sut.loadPreview()

        guard case let .media(_, videoDuration) = sut.preview else {
            Issue.record("the loaded image should be shown")
            return
        }
        #expect(videoDuration == nil)
    }

    @Test("a video shows the loaded preview together with its duration")
    func loadPreview_video_showsMediaWithDuration() async {
        let sut = makeSUT(
            node: NodeEntity(name: "Hobbiton.mp4", hasPreview: true, duration: 170),
            loadedPreview: .init(image: Image(systemName: "photo"), type: .preview)
        )

        await sut.loadPreview()

        guard case let .media(_, videoDuration) = sut.preview else {
            Issue.record("the loaded image should be shown")
            return
        }
        #expect(videoDuration == "2:50")
    }

    @Test("a media file whose preview cannot be loaded keeps its file type icon")
    func loadPreview_loaderYieldsNothing_keepsFileTypeIcon() async {
        let sut = makeSUT(node: NodeEntity(name: "elcapitan.jpeg", hasPreview: true))

        await sut.loadPreview()

        #expect(isFileTypeIcon(sut.preview))
    }

    @Test("media without a preview attribute is not requested at all")
    func loadPreview_mediaWithoutPreviewAttribute_doesNotAskTheLoader() async {
        let thumbnailLoader = MockThumbnailLoader()
        let sut = makeSUT(node: NodeEntity(name: "elcapitan.jpeg"), thumbnailLoader: thumbnailLoader)

        await sut.loadPreview()

        #expect(thumbnailLoader.invocations.isEmpty)
    }

    /// A PDF carries a preview of its first page, but the design asks for the file type icon, so the
    /// preview must not be requested for it.
    @Test("a non media file is not requested even when it carries a preview")
    func loadPreview_nonMediaWithPreviewAttribute_doesNotAskTheLoader() async {
        let thumbnailLoader = MockThumbnailLoader()
        let sut = makeSUT(
            node: NodeEntity(name: "roadmap.pdf", hasPreview: true),
            thumbnailLoader: thumbnailLoader
        )

        await sut.loadPreview()

        #expect(thumbnailLoader.invocations.isEmpty)
        #expect(isFileTypeIcon(sut.preview))
    }

    // The size is composed the same way the subject does rather than spelled out, so the assertions
    // are about the line being built, not about how Foundation spaces byte counts.
    @Test("a file that carries no duration is described by its size alone")
    func details_nonMedia_isSizeOnly() {
        let sut = makeSUT(node: NodeEntity(name: "Readme.rtf", size: 196_608))

        #expect(sut.details == size(196_608))
    }

    @Test("media is described by its duration and its size", arguments: ["Hobbiton.mp4", "Voice Note.mp3"])
    func details_media_isDurationAndSize(fileName: String) {
        let sut = makeSUT(node: NodeEntity(name: fileName, size: 10_485_760, duration: 170))

        #expect(sut.details == "2:50 • \(size(10_485_760))")
    }

    @Test("an hour long file spells the hour out")
    func details_mediaOverAnHour_includesHours() {
        let sut = makeSUT(node: NodeEntity(name: "Hobbiton.mp4", size: 10_485_760, duration: 3_723))

        #expect(sut.details == "1:02:03 • \(size(10_485_760))")
    }

    @Test("media with no duration on the node falls back to its size")
    func details_mediaWithoutDuration_isSizeOnly() {
        let sut = makeSUT(node: NodeEntity(name: "Hobbiton.mp4", size: 10_485_760))

        #expect(sut.details == size(10_485_760))
    }

    @Test("the name is shown as it is")
    func name_isNodeName() {
        let sut = makeSUT(node: NodeEntity(name: "elcapitan.jpeg"))

        #expect(sut.name == "elcapitan.jpeg")
    }

    private func makeSUT(
        node: NodeEntity,
        loadedPreview: ImageContainer? = nil,
        thumbnailLoader: MockThumbnailLoader? = nil
    ) -> FileLinkContentViewModel {
        let loader = thumbnailLoader ?? MockThumbnailLoader(
            loadImage: loadedPreview.map {
                SingleItemAsyncSequence<any ImageContaining>(item: $0).eraseToAnyAsyncSequence()
            } ?? EmptyAsyncSequence<any ImageContaining>().eraseToAnyAsyncSequence()
        )
        return FileLinkContentViewModel(node: node, thumbnailLoader: loader)
    }

    private func size(_ byteCount: Int64) -> String {
        String.memoryStyleString(fromByteCount: byteCount)
    }

    private func isFileTypeIcon(_ preview: FileLinkContentViewModel.Preview) -> Bool {
        if case .fileTypeIcon = preview { true } else { false }
    }
}

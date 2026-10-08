@testable import MEGA
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import Testing

@Suite("TextEditorViewModel reading position and left off item")
@MainActor
struct TextEditorViewModelReadingPositionTests {

    // MARK: - Saving the reading position

    @Test("Saves the anchor when the progress sits between the thresholds")
    func savesAnchorInsideThresholds() {
        let resumeUseCase = MockResumeTextPositionUseCase()
        let sut = makeSUT(resumeTextPositionUseCase: resumeUseCase)

        sut.dispatch(.updateReadingPosition(anchor: 500, progress: 0.5))
        sut.dispatch(.saveReadingPosition)

        #expect(resumeUseCase.savedOffsets == ["fingerprint": 500])
    }

    @Test("Does not save when the progress is below the minimum")
    func doesNotSaveBelowMinimum() {
        let resumeUseCase = MockResumeTextPositionUseCase()
        let sut = makeSUT(resumeTextPositionUseCase: resumeUseCase)

        sut.dispatch(.updateReadingPosition(anchor: 500, progress: 0.05))
        sut.dispatch(.saveReadingPosition)

        #expect(resumeUseCase.savedOffsets.isEmpty)
        #expect(resumeUseCase.saveReadingOffsetCallCount == 0)
    }

    @Test("Deletes the stored offset once the reader scrolls back to the start")
    func deletesStoredOffsetWhenBackAtTheStart() {
        let resumeUseCase = MockResumeTextPositionUseCase(savedOffsets: ["fingerprint": 500])
        let sut = makeSUT(resumeTextPositionUseCase: resumeUseCase)

        sut.dispatch(.updateReadingPosition(anchor: 20, progress: 0.05))
        sut.dispatch(.saveReadingPosition)

        #expect(resumeUseCase.savedOffsets.isEmpty)
        #expect(resumeUseCase.deleteReadingOffsetCallCount == 1)
    }

    @Test("Deletes the stored offset once the file is read to the end")
    func deletesStoredOffsetAtEndOfFile() {
        let resumeUseCase = MockResumeTextPositionUseCase(savedOffsets: ["fingerprint": 500])
        let sut = makeSUT(resumeTextPositionUseCase: resumeUseCase)

        sut.dispatch(.updateReadingPosition(anchor: 900, progress: 0.99))
        sut.dispatch(.saveReadingPosition)

        #expect(resumeUseCase.savedOffsets.isEmpty)
        #expect(resumeUseCase.deleteReadingOffsetCallCount == 1)
    }

    // MARK: - Resuming the reading position

    @Test("Resumes a plain text file at the stored offset")
    func resumesPlainTextFileAtStoredOffset() {
        let resumeUseCase = MockResumeTextPositionUseCase(savedOffsets: ["fingerprint": 777])
        let sut = makeSUT(fileName: "note.txt", resumeTextPositionUseCase: resumeUseCase)

        #expect(configuredModel(of: sut)?.resumeReadingOffset == 777)
    }

    @Test("Resumes a markdown file at nil, because the preview cannot measure the position")
    func doesNotResumeMarkdownFile() {
        let resumeUseCase = MockResumeTextPositionUseCase(savedOffsets: ["fingerprint": 777])
        let sut = makeSUT(fileName: "note.md", resumeTextPositionUseCase: resumeUseCase)

        #expect(configuredModel(of: sut)?.resumeReadingOffset == nil)
    }

    // MARK: - Left off item

    @Test("Records the left off item while the reader is short of the end")
    func recordsLeftOffItemBeforeTheEnd() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)

        await waitForLeftOffCall(on: recordUseCase) {
            sut.dispatch(.updateReadingPosition(anchor: 500, progress: 0.5))
            sut.dispatch(.saveReadingPosition)
        }

        #expect(recordUseCase.record_Calls.map(\.handle) == [1])
        #expect(recordUseCase.record_Calls.map(\.name) == ["note.txt"])
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    @Test("Removes the left off item once the reader is near the end")
    func removesLeftOffItemNearTheEnd() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)

        await waitForLeftOffCall(on: recordUseCase) {
            sut.dispatch(.updateReadingPosition(anchor: 900, progress: 0.92))
            sut.dispatch(.saveReadingPosition)
        }

        #expect(recordUseCase.remove_Calls == [1])
        #expect(recordUseCase.record_Calls.isEmpty)
    }

    // MARK: - Node identity after an edit

    @Test("Uses the node the upload produced, not the one the editor opened")
    func refreshesNodeEntityAfterSuccessfulUpload() async {
        let newNode = NodeEntity(name: "new.txt", fingerprint: "new", handle: 999, isFile: true)
        let uploadUseCase = MockUploadFileUseCase(
            duplicate: false,
            uploadFileResult: .success(()),
            filename: "\(UUID().uuidString).txt",
            nodeEntity: newNode,
            transfer: TransferEntity(nodeHandle: newNode.handle)
        )
        let resumeUseCase = MockResumeTextPositionUseCase(savedOffsets: ["fingerprint": 500])
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(
            textEditorMode: .edit,
            uploadFileUseCase: uploadUseCase,
            resumeTextPositionUseCase: resumeUseCase,
            leftOffItemRecordUseCase: recordUseCase
        )

        sut.dispatch(.uploadFile)

        await waitForLeftOffCall(on: recordUseCase) {
            sut.dispatch(.updateReadingPosition(anchor: 10, progress: 0.5))
            sut.dispatch(.saveReadingPosition)
        }

        #expect(recordUseCase.record_Calls.map(\.handle) == [newNode.handle])
        #expect(recordUseCase.record_Calls.map(\.name) == ["new.txt"])
        #expect(resumeUseCase.savedOffsets == ["new": 10])
    }

    // MARK: - Helpers

    private func makeSUT(
        fileName: String = "note.txt",
        textEditorMode: TextEditorMode = .view,
        uploadFileUseCase: MockUploadFileUseCase = MockUploadFileUseCase(),
        resumeTextPositionUseCase: MockResumeTextPositionUseCase = MockResumeTextPositionUseCase(),
        leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase = MockLeftOffItemRecordUseCase()
    ) -> TextEditorViewModel {
        TextEditorViewModel(
            router: MockTextEditorViewRouter(),
            textFile: TextFile(fileName: fileName),
            textEditorMode: textEditorMode,
            uploadFileUseCase: uploadFileUseCase,
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(),
            backupsUseCase: MockBackupsUseCase(),
            resumeTextPositionUseCase: resumeTextPositionUseCase,
            parentHandle: 1,
            nodeEntity: NodeEntity(name: fileName, fingerprint: "fingerprint", handle: 1, isFile: true),
            leftOffItemRecordUseCase: leftOffItemRecordUseCase,
            tracker: MockTracker()
        )
    }

    /// The model reaches the view through `configView`, so that command is the only way to read it.
    private func configuredModel(of sut: TextEditorViewModel) -> TextEditorModel? {
        var model: TextEditorModel?
        sut.invokeCommand = { command in
            if case .configView(let configured, _, _, _) = command {
                model = configured
            }
        }
        sut.dispatch(.setUpView)
        return model
    }

    /// The recording runs in an unstructured task, so the test waits for the mock to report the call
    /// instead of sleeping for an arbitrary time.
    private func waitForLeftOffCall(
        on useCase: MockLeftOffItemRecordUseCase,
        _ body: () -> Void
    ) async {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        useCase.onCall = { continuation.yield() }
        body()
        var iterator = stream.makeAsyncIterator()
        _ = await iterator.next()
        useCase.onCall = nil
    }
}

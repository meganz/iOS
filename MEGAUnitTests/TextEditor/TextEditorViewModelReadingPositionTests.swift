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

    @Test("Does not resume a markdown file on the plain text screen")
    func doesNotResumeMarkdownFile() {
        let resumeUseCase = MockResumeTextPositionUseCase(savedOffsets: ["fingerprint": 777], savedLines: ["fingerprint": 12])
        let sut = makeSUT(fileName: "note.md", resumeTextPositionUseCase: resumeUseCase)

        #expect(configuredModel(of: sut)?.resumeReadingOffset == nil)
    }

    @Test("Resumes a markdown file at the stored line on the Markdown screen, not at the stored offset")
    func resumesMarkdownScreenAtStoredLine() {
        let resumeUseCase = MockResumeTextPositionUseCase(savedOffsets: ["fingerprint": 777], savedLines: ["fingerprint": 12])
        let sut = makeSUT(fileName: "note.md", resumeTextPositionUseCase: resumeUseCase, isMarkdownScreen: true)

        #expect(configuredModel(of: sut)?.resumeReadingOffset == 12)
    }

    @Test(
        "Saves the top line of the Markdown preview only when the progress sits between the thresholds",
        arguments: [(0, 0.05, nil), (10, 0.1, nil), (50, 0.7, 50), (95, 0.95, nil), (90, 1, nil)] as [(Int, Double, Int?)]
    )
    func savesMarkdownTopLine(line: Int, progress: Double, savedLine: Int?) {
        let resumeUseCase = MockResumeTextPositionUseCase(savedOffsets: ["fingerprint": 500], savedLines: ["fingerprint": 40])
        let sut = makeSUT(fileName: "note.md", resumeTextPositionUseCase: resumeUseCase, isMarkdownScreen: true)

        sut.dispatch(.updateReadingPosition(anchor: line, progress: progress))
        sut.dispatch(.saveReadingPosition)

        #expect(resumeUseCase.savedLines["fingerprint"] == savedLine)
        #expect(resumeUseCase.savedOffsets == ["fingerprint": 500])
    }

    @Test("Close does not save the reading position, the screen saves it once when it disappears")
    func closeDoesNotSaveTheReadingPosition() {
        let resumeUseCase = MockResumeTextPositionUseCase()
        let sut = makeSUT(fileName: "note.md", resumeTextPositionUseCase: resumeUseCase, isMarkdownScreen: true)

        sut.dispatch(.updateReadingPosition(anchor: 50, progress: 0.7))
        sut.dispatch(.dismissTextEditorVC)

        #expect(resumeUseCase.saveReadingLineCallCount == 0)
        #expect(resumeUseCase.savedLines.isEmpty)
    }

    @Test("Removes the left off item once the last row of the Markdown preview is on screen")
    func removesLeftOffItemAtTheEndOfTheMarkdownPreview() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(fileName: "note.md", leftOffItemRecordUseCase: recordUseCase, isMarkdownScreen: true)

        await waitForLeftOffCall(on: recordUseCase) {
            sut.dispatch(.updateReadingPosition(anchor: 90, progress: 1))
            sut.dispatch(.saveReadingPosition)
        }

        #expect(recordUseCase.remove_Calls == [1])
        #expect(recordUseCase.record_Calls.isEmpty)
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

    @Test("Removes the left off item once the reader is near the end", arguments: [0.9, 0.92])
    func removesLeftOffItemNearTheEnd(progress: Double) async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase)

        await waitForLeftOffCall(on: recordUseCase) {
            sut.dispatch(.updateReadingPosition(anchor: 900, progress: progress))
            sut.dispatch(.saveReadingPosition)
        }

        #expect(recordUseCase.remove_Calls == [1])
        #expect(recordUseCase.record_Calls.isEmpty)
    }

    @Test("Removes the left off item when a file with no visible text closes without a position report", arguments: ["", " \n\n\t\n"])
    func removesLeftOffItemForBlankFileWithoutProgress(content: String) async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(content: content, leftOffItemRecordUseCase: recordUseCase)

        await waitForLeftOffCall(on: recordUseCase) {
            sut.dispatch(.saveReadingPosition)
        }

        #expect(recordUseCase.remove_Calls == [1])
        #expect(recordUseCase.record_Calls.isEmpty)
    }

    @Test("Records the left off item when a file with text closes without a position report")
    func recordsLeftOffItemForFileWithTextWithoutProgress() async {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(content: "Some text", leftOffItemRecordUseCase: recordUseCase)

        await waitForLeftOffCall(on: recordUseCase) {
            sut.dispatch(.saveReadingPosition)
        }

        #expect(recordUseCase.record_Calls.map(\.handle) == [1])
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    @Test("Does not record a file from a link, because Home can only reopen files of the account")
    func linkFileIsNotRecordedAsLeftOffItem() async throws {
        let recordUseCase = MockLeftOffItemRecordUseCase()
        let sut = makeSUT(leftOffItemRecordUseCase: recordUseCase, isLink: true)

        sut.dispatch(.updateReadingPosition(anchor: 500, progress: 0.5))
        sut.dispatch(.saveReadingPosition)
        // A record would run in a task, so the test gives that task time to run.
        try await Task.sleep(for: .milliseconds(200))

        #expect(recordUseCase.record_Calls.isEmpty)
        #expect(recordUseCase.remove_Calls.isEmpty)
    }

    // MARK: - Source rules

    @Test func textEditorModel_cloudDriveSource_hasNodeAccessLevel() {
        let sut = makeSUT(source: .cloudDrive, nodeAccessLevel: .owner)

        #expect(configuredModel(of: sut)?.accessLevel == .owner)
    }

    @Test(arguments: [TextEditorFileSource.offline, .chat, .transfers, .versions])
    func textEditorModel_otherSource_hasNoAccessLevel(source: TextEditorFileSource) {
        let sut = makeSUT(source: source, nodeAccessLevel: .owner)

        #expect(configuredModel(of: sut)?.accessLevel == nil)
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

    @Test("Deletes both the stored offset and the stored line after an edit is uploaded")
    func deletesOffsetAndLineAfterSuccessfulUpload() {
        let uploadUseCase = MockUploadFileUseCase(
            duplicate: false,
            uploadFileResult: .success(()),
            filename: "\(UUID().uuidString).md"
        )
        let resumeUseCase = MockResumeTextPositionUseCase(savedOffsets: ["fingerprint": 500], savedLines: ["fingerprint": 40])
        let sut = makeSUT(
            fileName: "note.md",
            textEditorMode: .edit,
            uploadFileUseCase: uploadUseCase,
            resumeTextPositionUseCase: resumeUseCase,
            isMarkdownScreen: true
        )

        sut.dispatch(.uploadFile)

        #expect(resumeUseCase.deleteReadingOffsetCallCount == 1)
        #expect(resumeUseCase.deleteReadingLineCallCount == 1)
        #expect(resumeUseCase.savedOffsets.isEmpty)
        #expect(resumeUseCase.savedLines.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT(
        fileName: String = "note.txt",
        content: String = "",
        textEditorMode: TextEditorMode = .view,
        uploadFileUseCase: MockUploadFileUseCase = MockUploadFileUseCase(),
        resumeTextPositionUseCase: MockResumeTextPositionUseCase = MockResumeTextPositionUseCase(),
        leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase = MockLeftOffItemRecordUseCase(),
        isLink: Bool = false,
        source: TextEditorFileSource = .cloudDrive,
        nodeAccessLevel: NodeAccessTypeEntity = .unknown,
        isMarkdownScreen: Bool = false
    ) -> TextEditorViewModel {
        TextEditorViewModel(
            router: MockTextEditorViewRouter(),
            textFile: TextFile(fileName: fileName, content: content, size: 0, encode: String.Encoding.utf8.rawValue),
            textEditorMode: textEditorMode,
            uploadFileUseCase: uploadFileUseCase,
            downloadNodeUseCase: MockDownloadNodeUseCase(),
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: nodeAccessLevel),
            backupsUseCase: MockBackupsUseCase(),
            networkMonitorUseCase: MockNetworkMonitorUseCase(),
            resumeTextPositionUseCase: resumeTextPositionUseCase,
            parentHandle: 1,
            nodeEntity: NodeEntity(name: fileName, fingerprint: "fingerprint", handle: 1, isFile: true),
            isMarkdownScreen: isMarkdownScreen,
            isLink: isLink,
            source: source,
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

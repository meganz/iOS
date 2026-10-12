import Foundation
@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGATextEditor
import Testing

@MainActor
struct TextEditorViewModelMarkdownTests {
    private struct Fixture {
        let sut: TextEditorViewModel
        let router: MockTextEditorViewRouter
        let path: String
        let commands: CommandLog
        let tracker: MockTracker
    }

    private final class CommandLog {
        var commands: [TextEditorViewModel.Command] = []

        var shownModels: [TextEditorModel] {
            commands.compactMap {
                if case .configView(let model, _, _, _) = $0 { model } else { nil }
            }
        }
    }

    private static func makeFixture(fileName: String, bytes: [UInt8], isMarkdownScreen: Bool) throws -> Fixture {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent(fileName).path
        try Data(bytes).write(to: URL(fileURLWithPath: path))

        let transfer = TransferEntity(
            type: .download,
            transferString: nil,
            startTime: nil,
            transferredBytes: 1,
            totalBytes: 1,
            path: path,
            parentPath: nil,
            nodeHandle: 123,
            parentHandle: 123,
            startPos: nil,
            endPos: nil,
            fileName: nil,
            numRetry: 1,
            maxRetries: 1,
            tag: 1,
            speed: 0,
            deltaSize: nil,
            updateTime: nil,
            publicNode: nil,
            isStreamingTransfer: false,
            isForeignOverquota: false,
            lastErrorExtended: nil,
            isFolderTransfer: false,
            folderTransferTag: .zero,
            appData: nil,
            state: .none,
            priority: 123,
            stage: .none
        )
        let router = MockTextEditorViewRouter()
        let tracker = MockTracker()
        let sut = TextEditorViewModel(
            router: router,
            textFile: TextFile(fileName: fileName),
            textEditorMode: .load,
            uploadFileUseCase: MockUploadFileUseCase(),
            downloadNodeUseCase: MockDownloadNodeUseCase(transferEntity: transfer, result: .success(transfer)),
            nodeUseCase: MockNodeDataUseCase(nodeAccessLevelVariable: .owner),
            backupsUseCase: MockBackupsUseCase(),
            resumeTextPositionUseCase: MockResumeTextPositionUseCase(),
            nodeEntity: NodeEntity(handle: 123, isFile: true),
            isMarkdownScreen: isMarkdownScreen,
            tracker: tracker
        )
        let log = CommandLog()
        sut.invokeCommand = { log.commands.append($0) }
        return Fixture(sut: sut, router: router, path: path, commands: log, tracker: tracker)
    }

    /// The download runs in a task. The test waits until the screen shows the file or the document preview opens.
    private static func openFile(_ fixture: Fixture, sourceLocation: SourceLocation = #_sourceLocation) async throws {
        fixture.sut.dispatch(.setUpView)
        let isOpen = { fixture.commands.shownModels.count >= 2 || fixture.router.presentPreviewDocVC_calledTimes > 0 }
        for _ in 0..<500 where !isOpen() {
            try await Task.sleep(for: .milliseconds(10))
        }
        if !isOpen() { Issue.record("The file did not open within 5 seconds", sourceLocation: sourceLocation) }
    }

    // MARK: - Gate

    private static func isGateOn(remoteFlag: Bool) -> Bool {
        TextEditorViewModel.isMarkdownEditorEnabled(
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.iosMarkdownEditor: remoteFlag])
        )
    }

    @Test func gateIsOnWithRemoteFlag() {
        #expect(Self.isGateOn(remoteFlag: true))
    }

    @Test func gateIsOffWithoutRemoteFlag() {
        #expect(!Self.isGateOn(remoteFlag: false))
    }

    // MARK: - Download

    @Test func markdownDownloadWithValidUTF8ShowsText() async throws {
        let fixture = try Self.makeFixture(fileName: "notes.md", bytes: Array("# Héllo".utf8), isMarkdownScreen: true)

        try await Self.openFile(fixture)

        let shown = try #require(fixture.commands.shownModels.last)
        #expect(shown.textEditorMode == .view)
        #expect(shown.textFile.content == "# Héllo")
        #expect(shown.textFile.encode == String.Encoding.utf8.rawValue)
        #expect(fixture.router.presentPreviewDocVC_calledTimes == 0)
    }

    @Test func markdownDownloadWithInvalidUTF8OpensDocumentPreview() async throws {
        // 0xFF and 0xFE never appear in UTF-8.
        let fixture = try Self.makeFixture(fileName: "notes.md", bytes: [0x23, 0x20, 0xFF, 0xFE, 0x41], isMarkdownScreen: true)

        try await Self.openFile(fixture)

        #expect(fixture.router.presentPreviewDocVC_calledTimes == 1)
        #expect(fixture.router.presentPreviewDocVC_path == fixture.path)
        #expect(fixture.commands.shownModels.allSatisfy { $0.textEditorMode == .load })
    }

    @Test func plainTextDownloadKeepsUsedEncodingDecode() async throws {
        // Valid UTF-16 with a byte order mark. The strict UTF-8 check would reject it.
        let utf16 = Array("héllo".data(using: .utf16)!)
        let fixture = try Self.makeFixture(fileName: "notes.txt", bytes: utf16, isMarkdownScreen: false)

        try await Self.openFile(fixture)

        let shown = try #require(fixture.commands.shownModels.last)
        #expect(shown.textEditorMode == .view)
        #expect(shown.textFile.content == "héllo")
        #expect(shown.textFile.encode == String.Encoding.utf16.rawValue)
        #expect(fixture.router.presentPreviewDocVC_calledTimes == 0)
    }

    // MARK: - Mode menu analytics

    private static func trackedEventNames(_ fixture: Fixture) -> [String] {
        fixture.tracker.trackedEventIdentifiers.map { String(describing: type(of: $0)) }
    }

    private static func makeModeFixture() throws -> Fixture {
        try makeFixture(fileName: "notes.md", bytes: Array("# Title".utf8), isMarkdownScreen: true)
    }

    @Test func selectRichTextModeTracksRichTextModeMenuItemEventOnce() throws {
        let fixture = try Self.makeModeFixture()

        fixture.sut.dispatch(.selectMarkdownMode(.richText))

        #expect(Self.trackedEventNames(fixture) == [String(describing: TextEditorRichTextModeMenuItemEvent.self)])
    }

    @Test func selectPlainTextModeTracksPlainTextModeMenuItemEventOnce() throws {
        let fixture = try Self.makeModeFixture()

        fixture.sut.dispatch(.selectMarkdownMode(.plainText))

        #expect(Self.trackedEventNames(fixture) == [String(describing: TextEditorPlainTextModeMenuItemEvent.self)])
    }

    @Test func selectSameModeTwiceTracksTwoEvents() throws {
        let fixture = try Self.makeModeFixture()

        fixture.sut.dispatch(.selectMarkdownMode(.richText))
        fixture.sut.dispatch(.selectMarkdownMode(.richText))

        let richName = String(describing: TextEditorRichTextModeMenuItemEvent.self)
        #expect(Self.trackedEventNames(fixture) == [richName, richName])
    }

    @Test func setUpViewTracksNoModeMenuItemEvent() throws {
        let fixture = try Self.makeModeFixture()

        fixture.sut.dispatch(.setUpView)

        let modeEventNames = [
            String(describing: TextEditorRichTextModeMenuItemEvent.self),
            String(describing: TextEditorPlainTextModeMenuItemEvent.self)
        ]
        #expect(Self.trackedEventNames(fixture).allSatisfy { !modeEventNames.contains($0) })
    }
}

import Foundation
import MEGADomain
import MEGADomainMock
@testable import MEGAPDFViewer
import PDFKit
import Testing

private final class LockedDocumentURLUseCase: PDFDocumentURLUseCaseProtocol {
    let url: URL
    private(set) var callCount = 0

    init(url: URL) {
        self.url = url
    }

    func localDocumentURL(for pdfDocumentSource: PDFViewerDocumentSource) -> AsyncThrowingStream<PDFDocumentLoadEvent, any Error> {
        callCount += 1
        return AsyncThrowingStream { continuation in
            continuation.yield(.ready(url))
            continuation.finish()
        }
    }
}

@MainActor
struct PDFViewerDocumentLockedTests {
    private struct Context {
        let sut: PDFViewerViewModel
        let document: MockLockablePDFDocument
        let urlUseCase: LockedDocumentURLUseCase
        let loadingUseCase: MockPDFViewerDocumentLoadingUseCase
        let unlocker: MockPDFDocumentUnlocker
        let lastPageUseCase: MockPDFViewerLastPageUseCase
    }

    @Test func loadDocument_whenLocked_keepsDocumentUnavailableAndSubmissionDisabled() async throws {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()

        #expect(context.sut.isDocumentLocked)
        #expect(context.sut.state.isDocumentLocked)
        #expect(!context.sut.state.isReady)
        #expect(context.sut.pdfDocument == nil)
        #expect(context.sut.thumbnailLoader == nil)
        #expect(context.sut.password.isEmpty)
        #expect(!context.sut.isSubmissionEnabled)
        #expect(!context.sut.showInvalidPasswordError)
        #expect(!context.sut.isShowingDamagedFileAlert)
        #expect(context.unlocker.invocations.isEmpty)
        guard case .documentLocked(let lockedState) = context.sut.state else {
            Issue.record("Expected documentLocked state")
            return
        }
        #expect(lockedState.document === context.document)
        #expect(lockedState.localDocumentURL == context.urlUseCase.url)
    }

    @Test func loadDocument_whenLockedAgain_doesNotResolveOrParseAgain() async {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()
        context.sut.password = "draft"
        await context.sut.loadDocumentFromSource()

        #expect(context.sut.isPasswordEntryPresented)
        #expect(context.sut.password == "draft")
        #expect(context.urlUseCase.callCount == 1)
        #expect(context.loadingUseCase.loadURLs == [context.urlUseCase.url])
        #expect(context.sut.isDocumentLocked)
    }

    @Test func submitPassword_whenInputEmpty_disablesSubmissionWithoutRejecting() async {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()

        #expect(!context.sut.isSubmissionEnabled)
        await context.sut.submitPassword()
        #expect(context.unlocker.invocations.isEmpty)
        #expect(!context.sut.showInvalidPasswordError)
        #expect(context.sut.passwordRejectionCount == 0)

        context.sut.password = "   "
        #expect(context.sut.isSubmissionEnabled)
        #expect(context.sut.password == "   ")
        context.sut.password = ""
        #expect(!context.sut.isSubmissionEnabled)
    }

    @Test func passwordEdit_storesExactValueAndDisablesEmptySubmission() async {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()

        context.sut.password = " test-password "
        #expect(context.sut.password == " test-password ")
        #expect(context.sut.isSubmissionEnabled)

        context.sut.password = ""
        #expect(context.sut.password.isEmpty)
        #expect(!context.sut.isSubmissionEnabled)
    }

    @Test(arguments: [" test-password ", "   "])
    func submitPassword_forwardsExactInputIncludingWhitespace(password: String) async throws {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()
        context.sut.password = password

        await context.sut.submitPassword()

        #expect(context.unlocker.invocations.count == 1)
        let invocation = try #require(context.unlocker.invocations.first)
        #expect(invocation.document === context.document)
        #expect(invocation.password == password)
        #expect(context.loadingUseCase.preparationInvocations.isEmpty)
    }

    @Test func submitPassword_whenRejected_clearsInputShowsErrorAndAllowsRetry() async {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()
        context.sut.password = "wrong"

        await context.sut.submitPassword()

        #expect(context.sut.isDocumentLocked)
        #expect(context.sut.password.isEmpty)
        #expect(context.sut.showInvalidPasswordError)
        #expect(!context.sut.isSubmissionEnabled)
        #expect(context.sut.pdfDocument == nil)
        #expect(context.loadingUseCase.preparationInvocations.isEmpty)
        #expect(context.lastPageUseCase.invocations.isEmpty)
    }

    @Test func submitPassword_afterRejection_ignoresEmptyRetryAndPreservesFeedback() async {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()
        context.sut.password = "wrong"
        await context.sut.submitPassword()
        #expect(!context.sut.isSubmissionEnabled)
        #expect(context.sut.passwordRejectionCount == 1)

        await context.sut.submitPassword()

        #expect(context.unlocker.invocations.map(\.password) == ["wrong"])
        #expect(!context.sut.isSubmissionEnabled)
        #expect(context.sut.showInvalidPasswordError)
        #expect(context.sut.passwordRejectionCount == 1)
    }

    @Test func cancelPasswordEntry_keepsDocumentLockedAndSkipsLastPageSave() async {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()
        #expect(context.sut.isPasswordEntryPresented)
        context.sut.password = "unsubmitted"

        context.sut.cancelPasswordEntry()

        #expect(context.sut.isDocumentLocked)
        #expect(!context.sut.isPasswordEntryPresented)
        #expect(!context.sut.isSubmissionEnabled)
        #expect(context.sut.password.isEmpty)
        #expect(context.sut.pdfDocument == nil)
        await context.sut.submitPassword()
        await context.sut.loadDocumentFromSource()
        await context.sut.saveLastReadPage()
        #expect(context.unlocker.invocations.isEmpty)
        #expect(context.urlUseCase.callCount == 1)
        #expect(!context.sut.isPasswordEntryPresented)
        #expect(context.lastPageUseCase.invocations.isEmpty)
    }

    @Test func passwordEdit_afterRejection_clearsError() async {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()
        context.sut.password = "wrong"
        await context.sut.submitPassword()
        #expect(context.sut.showInvalidPasswordError)

        context.sut.password = "next-attempt"

        #expect(!context.sut.showInvalidPasswordError)
        #expect(context.sut.password == "next-attempt")
        #expect(context.sut.isSubmissionEnabled)
    }

    @Test func unchangedPasswordWrite_afterRejection_keepsError() async {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()
        context.sut.password = "wrong"
        await context.sut.submitPassword()

        context.sut.password = ""

        #expect(context.sut.showInvalidPasswordError)
    }

    @Test func submitPassword_afterRejectedAttempt_reusesDocumentAndLocalURL() async throws {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()
        context.sut.password = "wrong"
        await context.sut.submitPassword()
        context.unlocker.result = true
        context.sut.password = "correct"

        await context.sut.submitPassword()

        #expect(context.unlocker.invocations.count == 2)
        #expect(context.unlocker.invocations.allSatisfy { $0.document === context.document })
        #expect(context.urlUseCase.callCount == 1)
        let invocation = try #require(context.loadingUseCase.preparationInvocations.first)
        #expect(invocation.document === context.document)
        #expect(invocation.url == context.urlUseCase.url)
        #expect(invocation.password == "correct")
        context.sut.displayerDidFinishPreparingForDisplayAndInteraction()
        #expect(context.sut.state.isReady)
        #expect(context.sut.pdfDocument === context.document)
        #expect(context.sut.password.isEmpty)
    }

    @Test func submitPassword_whenPreparationSuspends_staysIntermediateAndRejectsDuplicate() async throws {
        let context = makeContext(unlockResult: true)
        context.loadingUseCase.suspendsPreparation = true
        await context.sut.loadDocumentFromSource()
        context.sut.password = "submitted"
        let task = startSubmission(context)
        await context.loadingUseCase.waitForOperationOrReturn()
        defer { context.loadingUseCase.resumePreparation() }

        #expect(context.loadingUseCase.preparationInvocations.count == 1)
        guard !context.loadingUseCase.preparationInvocations.isEmpty else {
            await task.value
            return
        }
        #expect(context.sut.isDocumentLocked)
        #expect(!context.sut.isSubmissionEnabled)
        #expect(context.sut.pdfDocument == nil)
        #expect(context.sut.thumbnailLoader == nil)

        await context.sut.loadDocumentFromSource()
        #expect(context.sut.isPasswordEntryPresented)
        #expect(context.urlUseCase.callCount == 1)
        await context.sut.submitPassword()
        #expect(context.unlocker.invocations.count == 1)
        context.loadingUseCase.resumePreparation()
        await task.value

        context.sut.displayerDidFinishPreparingForDisplayAndInteraction()
        #expect(context.sut.state.isReady)
        #expect(context.sut.pdfDocument === context.document)
        #expect(context.sut.thumbnailLoader != nil)
        #expect(context.sut.initialPageIndex == 2)
        #expect(context.sut.password.isEmpty)
        guard case .ready(let readyState) = context.sut.state else {
            Issue.record("Expected ready state after preparation")
            return
        }
        #expect(readyState.documentIdentifierForLastViewedPageIndex == "test-fingerprint")
    }

    @Test func cancelPasswordEntry_whilePreparing_preventsLateReadyAndSaving() async {
        let context = makeContext(unlockResult: true)
        context.loadingUseCase.suspendsPreparation = true
        await context.sut.loadDocumentFromSource()
        context.sut.password = "submitted"
        let task = startSubmission(context)
        await context.loadingUseCase.waitForOperationOrReturn()
        #expect(context.loadingUseCase.preparationInvocations.count == 1)

        task.cancel()
        context.sut.cancelPasswordEntry()
        context.loadingUseCase.resumePreparation()
        await task.value
        await context.sut.saveLastReadPage()

        #expect(context.sut.isDocumentLocked)
        #expect(!context.sut.isPasswordEntryPresented)
        #expect(!context.sut.state.isReady)
        #expect(context.sut.pdfDocument == nil)
        #expect(context.sut.password.isEmpty)
        #expect(!context.sut.showInvalidPasswordError)
        #expect(!context.sut.isShowingDamagedFileAlert)
        #expect(context.lastPageUseCase.invocations.isEmpty)
    }

    @Test func cancelPasswordEntry_withoutTaskCancellation_invalidatesLatePreparation() async {
        let context = makeContext(unlockResult: true)
        context.loadingUseCase.suspendsPreparation = true
        await context.sut.loadDocumentFromSource()
        context.sut.password = "submitted"
        let task = startSubmission(context)
        await context.loadingUseCase.waitForOperationOrReturn()
        #expect(context.loadingUseCase.preparationInvocations.count == 1)

        context.sut.cancelPasswordEntry()
        context.loadingUseCase.resumePreparation()
        await task.value

        #expect(context.sut.isDocumentLocked)
        #expect(!context.sut.isPasswordEntryPresented)
        #expect(!context.sut.state.isReady)
        #expect(context.sut.pdfDocument == nil)
    }

    @Test func saveLastReadPage_whileLocked_doesNotPersistPage() async {
        let context = makeContext()
        await context.sut.loadDocumentFromSource()
        #expect(context.sut.isDocumentLocked)

        await context.sut.saveLastReadPage()

        #expect(context.lastPageUseCase.invocations.isEmpty)
    }

    @Test func submitPassword_whenLoadingReturnsLocked_showsRejectionAndAllowsRetry() async {
        let context = makeContext(unlockResult: true)
        await context.sut.loadDocumentFromSource()
        context.sut.password = "test-password"
        context.loadingUseCase.unlockedLoadingResult = .documentLocked(.init(
            document: context.document,
            localDocumentURL: context.urlUseCase.url
        ))

        await context.sut.submitPassword()

        #expect(context.sut.isDocumentLocked)
        #expect(!context.sut.isSubmissionEnabled)
        #expect(context.sut.password.isEmpty)
        #expect(context.sut.showInvalidPasswordError)
        #expect(context.sut.passwordRejectionCount == 1)
        #expect(!context.sut.isShowingDamagedFileAlert)
        #expect(context.sut.pdfDocument == nil)
        #expect(context.sut.thumbnailLoader == nil)
    }

    @Test func submitPassword_whenPreparationThrows_clearsPasswordAndShowsFailure() async {
        let context = makeContext(unlockResult: true)
        context.loadingUseCase.preparationError = CocoaError(.fileReadCorruptFile)
        await context.sut.loadDocumentFromSource()
        context.sut.password = "submitted"

        await context.sut.submitPassword()

        #expect(context.sut.state.isFailed)
        #expect(!context.sut.showInvalidPasswordError)
        #expect(context.sut.password.isEmpty)
        #expect(context.sut.pdfDocument == nil)
    }

    @Test(arguments: ["locked-rc4", "locked-rc4-spaces"])
    func protectedFixture_wrongThenCorrectPassword_rendersIndependentThumbnail(name: String) async throws {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "pdf", subdirectory: "Fixtures"))
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let sut = PDFViewerViewModel(dependency: .init(
            pdfDocumentSource: .local(url),
            documentURLUseCase: LockedDocumentURLUseCase(url: url),
            documentLoadingUseCase: PDFViewerDocumentLoadingUseCase(
                documentLoader: PDFDocumentLoader(),
                outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: PDFDocumentLoader(), outlineReader: PDFOutlineReader()),
                lastPageUseCase: lastPageUseCase
            ),
            lastPageUseCase: lastPageUseCase,
            leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase(),
            node: nil,
            nearestOutlineItemUseCase: PDFNearestOutlineItemUseCase(),
            fileName: name
        ))
        await sut.loadDocumentFromSource()
        #expect(sut.isDocumentLocked)
        #expect(sut.pdfDocument == nil)
        #expect(lastPageUseCase.invocations.isEmpty)

        sut.password = "wrong"
        await sut.submitPassword()
        #expect(sut.showInvalidPasswordError)
        #expect(sut.isDocumentLocked)
        #expect(lastPageUseCase.invocations.isEmpty)

        sut.password = name == "locked-rc4-spaces" ? " secret " : "secret"
        await sut.submitPassword()

        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        #expect(sut.state.isReady)
        let document = try #require(sut.pdfDocument)
        #expect(!document.isLocked)
        #expect(document.string?.contains("Locked document, page one.") == true)
        let thumbnailLoader = try #require(sut.thumbnailLoader)
        let thumbnail = await thumbnailLoader.thumbnail(
            forPageAt: 0,
            size: CGSize(width: 100, height: 140),
            displayScale: 1
        )
        #expect(thumbnail != nil)
        #expect(sut.password.isEmpty)
    }

    @Test(arguments: ["secret", " secret "])
    func protectedOutlineFixture_loadsUnlockedContentsAfterReady(password: String) async throws {
        let url = try PDFDocument.makeTestDocumentURL(
            pageCount: 2,
            outline: [TestOutlineNode(label: "Chapter", pageIndex: 1)],
            password: password
        )
        defer { try? FileManager.default.removeItem(at: url) }
        let outlineUseCase = PDFOutlineLoadingUseCase(
            documentLoader: PDFDocumentLoader(),
            outlineReader: PDFOutlineReader()
        )
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let sut = PDFViewerViewModel(dependency: .init(
            pdfDocumentSource: .local(url),
            documentURLUseCase: LockedDocumentURLUseCase(url: url),
            documentLoadingUseCase: PDFViewerDocumentLoadingUseCase(
                documentLoader: PDFDocumentLoader(),
                outlineLoadingUseCase: outlineUseCase,
                lastPageUseCase: lastPageUseCase
            ),
            lastPageUseCase: lastPageUseCase,
            leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase(),
            node: nil,
            nearestOutlineItemUseCase: PDFNearestOutlineItemUseCase(),
            fileName: "protected-outline.pdf"
        ))
        await sut.loadDocumentFromSource()
        #expect(sut.isDocumentLocked)
        sut.password = password

        await sut.submitPassword()

        sut.displayerDidFinishPreparingForDisplayAndInteraction()
        #expect(sut.state.isReady)
        #expect(sut.showsOutlineButton)
        #expect(sut.outlineItems.isEmpty)
        #expect(sut.outlineDocumentURL == url)
        await sut.loadOutlineIfNeeded()
        #expect(sut.outlineItems.map(\.title) == ["Chapter"])
        #expect(sut.outlineItems.map(\.pageIndex) == [1])
        #expect(sut.outlineDocumentURL == nil)
        #expect(sut.password.isEmpty)
    }

    private func startSubmission(_ context: Context) -> Task<Void, Never> {
        Task {
            await context.sut.submitPassword()
            context.loadingUseCase.operationDidReturn()
        }
    }

    private func makeContext(
        unlockResult: Bool = false
    ) -> Context {
        let document = MockLockablePDFDocument()
        for index in 0..<3 { document.insert(PDFPage(), at: index) }
        let url = URL(fileURLWithPath: "/tmp/locked-viewer-test.pdf")
        let urlUseCase = LockedDocumentURLUseCase(url: url)
        let unlocker = MockPDFDocumentUnlocker(result: unlockResult)
        let loadingUseCase = MockPDFViewerDocumentLoadingUseCase(document: document, url: url, documentUnlocker: unlocker)
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let sut = PDFViewerViewModel(dependency: .init(
            pdfDocumentSource: .local(url),
            documentURLUseCase: urlUseCase,
            documentLoadingUseCase: loadingUseCase,
            lastPageUseCase: lastPageUseCase,
            leftOffItemRecordUseCase: MockLeftOffItemRecordUseCase(),
            node: nil,
            nearestOutlineItemUseCase: PDFNearestOutlineItemUseCase(),
            fileName: "locked-test.pdf"
        ))
        return Context(
            sut: sut,
            document: document,
            urlUseCase: urlUseCase,
            loadingUseCase: loadingUseCase,
            unlocker: unlocker,
            lastPageUseCase: lastPageUseCase
        )
    }
}

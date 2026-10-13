import Foundation
@testable import MEGAPDFViewer
import PDFKit
import Testing

@MainActor
struct PDFViewerLockedDocumentLoadingTests {
    private let url = URL(fileURLWithPath: "/tmp/locked-test.pdf")

    @Test func loadDocument_whenLocked_returnsLockedWithoutUnlockOrPreparation() async throws {
        let document = MockLockablePDFDocument()
        let loader = RecordingPDFDocumentLoader(documents: [document])
        let unlocker = MockPDFDocumentUnlocker()
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let sut = PDFViewerDocumentLoadingUseCase(
            documentLoader: loader,
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: MockPDFDocumentLoader(document: nil), outlineReader: PDFOutlineReader()),
            lastPageUseCase: lastPageUseCase,
            documentUnlocker: unlocker
        )

        let result = try await sut.loadDocument(at: url)

        #expect(unlocker.invocations.isEmpty)
        #expect(lastPageUseCase.invocations.isEmpty)
        #expect(loader.urls == [url])
        guard case .documentLocked(let lockedState) = result else {
            Issue.record("Expected locked document instead of ready state")
            return
        }
        #expect(lockedState.document === document)
        #expect(lockedState.localDocumentURL == url)
    }

    @Test func loadDocument_whenEncryptedButUnlocked_returnsReadyWithoutUnlock() async throws {
        let document = MockLockablePDFDocument()
        document.locked = false
        let unlocker = MockPDFDocumentUnlocker()
        let sut = PDFViewerDocumentLoadingUseCase(
            documentLoader: RecordingPDFDocumentLoader(documents: [document, nil]),
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: MockPDFDocumentLoader(document: nil), outlineReader: PDFOutlineReader()),
            lastPageUseCase: MockPDFViewerLastPageUseCase(),
            documentUnlocker: unlocker
        )

        guard case .ready(let readyState) = try await sut.loadDocument(at: url) else {
            Issue.record("Expected ready state for accessible encrypted document")
            return
        }
        #expect(readyState.document === document)
        #expect(unlocker.invocations.isEmpty)
    }

    @Test(arguments: ["", " secret "])
    func unlockAndLoad_unlocksSeparateThumbnailWithExactSubmittedPassword(password: String) async throws {
        let document = MockPDFDocumentLoader.makeDocument(pageCount: 3)
        let thumbnailDocument = MockLockablePDFDocument()
        let loader = RecordingPDFDocumentLoader(documents: [thumbnailDocument])
        let unlocker = MockPDFDocumentUnlocker(result: true)
        let lastPageUseCase = MockPDFViewerLastPageUseCase(loadLastPageIndexResult: 2)
        let sut = PDFViewerDocumentLoadingUseCase(
            documentLoader: loader,
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: MockPDFDocumentLoader(document: nil), outlineReader: PDFOutlineReader()),
            lastPageUseCase: lastPageUseCase,
            documentUnlocker: unlocker
        )

        guard case .ready(let result) = try await sut.unlockAndLoad(document: document, documentUrl: url, password: password) else {
            Issue.record("Expected ready state for unlocked document")
            return
        }

        #expect(result.document === document)
        #expect(result.thumbnailDocument === thumbnailDocument)
        #expect(!thumbnailDocument.isLocked)
        #expect(result.initialPageIndex == 2)
        #expect(result.documentIdentifierForLastViewedPageIndex == "any-fingerprint")
        #expect(loader.urls == [url])
        let invocation = try #require(unlocker.invocations.first)
        #expect(unlocker.invocations.count == 1)
        #expect(invocation.document === thumbnailDocument)
        #expect(invocation.password == password)
    }

    @Test func unlockAndLoad_fromMainActor_parsesAndUnlocksThumbnailOffMainThread() async throws {
        let loader = RecordingPDFDocumentLoader(documents: [MockLockablePDFDocument()])
        let unlocker = MockPDFDocumentUnlocker(result: true)
        let sut = PDFViewerDocumentLoadingUseCase(
            documentLoader: loader,
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: PDFDocumentLoader(), outlineReader: PDFOutlineReader()),
            lastPageUseCase: MockPDFViewerLastPageUseCase(),
            documentUnlocker: unlocker
        )

        _ = try await sut.unlockAndLoad(
            document: MockPDFDocumentLoader.makeDocument(),
            documentUrl: url,
            password: "secret"
        )

        #expect(loader.isMainThreadInvocations == [false])
        #expect(unlocker.isMainThreadInvocations == [false])
    }

    @Test func loadDocument_withoutSubmittedPassword_doesNotInventUnlockAttempt() async throws {
        let document = MockPDFDocumentLoader.makeDocument()
        let unlocker = MockPDFDocumentUnlocker()
        let sut = PDFViewerDocumentLoadingUseCase(
            documentLoader: RecordingPDFDocumentLoader(documents: [document, MockLockablePDFDocument()]),
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: MockPDFDocumentLoader(document: nil), outlineReader: PDFOutlineReader()),
            lastPageUseCase: MockPDFViewerLastPageUseCase(),
            documentUnlocker: unlocker
        )

        guard case .ready(let result) = try await sut.loadDocument(at: url) else {
            Issue.record("Expected ready state for unlocked document")
            return
        }

        #expect(result.document === document)
        #expect(result.thumbnailDocument == nil)
        #expect(unlocker.invocations.isEmpty)
    }

    @Test func unlockAndLoad_whenThumbnailUnlockFails_preservesUsableDisplay() async throws {
        let document = MockPDFDocumentLoader.makeDocument()
        let sut = PDFViewerDocumentLoadingUseCase(
            documentLoader: RecordingPDFDocumentLoader(documents: [MockLockablePDFDocument()]),
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: MockPDFDocumentLoader(document: nil), outlineReader: PDFOutlineReader()),
            lastPageUseCase: MockPDFViewerLastPageUseCase(),
            documentUnlocker: MockPDFDocumentUnlocker(result: false)
        )

        guard case .ready(let result) = try await sut.unlockAndLoad(document: document, documentUrl: url, password: "test-password") else {
            Issue.record("Expected ready state for unlocked document")
            return
        }

        #expect(result.document === document)
        #expect(result.thumbnailDocument == nil)
    }

    @Test func unlockAndLoad_whenThumbnailParseFails_preservesUsableDisplay() async throws {
        let document = MockPDFDocumentLoader.makeDocument()
        let sut = PDFViewerDocumentLoadingUseCase(
            documentLoader: RecordingPDFDocumentLoader(documents: [nil]),
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: MockPDFDocumentLoader(document: nil), outlineReader: PDFOutlineReader()),
            lastPageUseCase: MockPDFViewerLastPageUseCase()
        )

        guard case .ready(let result) = try await sut.unlockAndLoad(document: document, documentUrl: url, password: "test-password") else {
            Issue.record("Expected ready state for unlocked document")
            return
        }

        #expect(result.document === document)
        #expect(result.thumbnailDocument == nil)
    }

    @Test func unlockAndLoad_whenDocumentRemainsLocked_returnsDocumentLocked() async throws {
        let document = MockLockablePDFDocument()
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let loader = RecordingPDFDocumentLoader(documents: [])
        let sut = PDFViewerDocumentLoadingUseCase(
            documentLoader: loader,
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: MockPDFDocumentLoader(document: nil), outlineReader: PDFOutlineReader()),
            lastPageUseCase: lastPageUseCase
        )

        let result = try await sut.unlockAndLoad(document: document, documentUrl: url, password: "wrong")
        guard case .documentLocked(let lockedState) = result else {
            Issue.record("Expected documentLocked state")
            return
        }
        #expect(lockedState.document === document)
        #expect(lockedState.localDocumentURL == url)
        #expect(lastPageUseCase.invocations.isEmpty)
        #expect(loader.urls.isEmpty)
    }

    @Test(arguments: ["", " secret ", "   "])
    func unlockAndLoad_unlocksDisplayAndThumbnailWithExactPassword(password: String) async throws {
        let document = MockLockablePDFDocument()
        let thumbnailDocument = MockLockablePDFDocument()
        let loader = RecordingPDFDocumentLoader(documents: [thumbnailDocument])
        let unlocker = MockPDFDocumentUnlocker(result: true)
        let sut = PDFViewerDocumentLoadingUseCase(
            documentLoader: loader,
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: PDFDocumentLoader(), outlineReader: PDFOutlineReader()),
            lastPageUseCase: MockPDFViewerLastPageUseCase(),
            documentUnlocker: unlocker
        )

        let state = try await sut.unlockAndLoad(document: document, documentUrl: url, password: password)

        guard case .ready(let readyState) = state else {
            Issue.record("Expected unlocked display and thumbnail documents")
            return
        }
        #expect(readyState.document === document)
        #expect(readyState.thumbnailDocument === thumbnailDocument)
        #expect(!document.isLocked)
        #expect(!thumbnailDocument.isLocked)
        #expect(unlocker.invocations.map(\.password) == [password, password])
        #expect(unlocker.isMainThreadInvocations == [true, false])
    }

    @Test func unlockAndLoad_whenUnlockReportsSuccessButDocumentRemainsLocked_returnsLocked() async throws {
        let document = MockLockablePDFDocument()
        let unlocker = MockPDFDocumentUnlocker(result: true)
        unlocker.unlocksDocument = false
        let loader = RecordingPDFDocumentLoader(documents: [])
        let lastPageUseCase = MockPDFViewerLastPageUseCase()
        let sut = PDFViewerDocumentLoadingUseCase(
            documentLoader: loader,
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: PDFDocumentLoader(), outlineReader: PDFOutlineReader()),
            lastPageUseCase: lastPageUseCase,
            documentUnlocker: unlocker
        )

        let state = try await sut.unlockAndLoad(document: document, documentUrl: url, password: "wrong")

        guard case .documentLocked(let lockedState) = state else {
            Issue.record("Expected locked state when the document is still locked")
            return
        }
        #expect(lockedState.document === document)
        #expect(loader.urls.isEmpty)
        #expect(lastPageUseCase.invocations.isEmpty)
    }

    @Test func unlockAndLoad_whenCancelled_doesNotReturnReady() async {
        let task = Task {
            let document = MockPDFDocumentLoader.makeDocument()
            let sut = PDFViewerDocumentLoadingUseCase(
                documentLoader: MockPDFDocumentLoader(document: document),
            outlineLoadingUseCase: PDFOutlineLoadingUseCase(documentLoader: MockPDFDocumentLoader(document: nil), outlineReader: PDFOutlineReader()),
                lastPageUseCase: MockPDFViewerLastPageUseCase()
            )
            withUnsafeCurrentTask { $0?.cancel() }
            _ = try await sut.unlockAndLoad(document: document, documentUrl: url, password: "test-password")
        }

        await #expect(throws: CancellationError.self) { try await task.value }
    }
}

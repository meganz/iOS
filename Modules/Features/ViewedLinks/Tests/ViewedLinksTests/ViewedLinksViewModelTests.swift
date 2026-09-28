import Foundation
import MEGAL10n
import Search
import Testing
@testable import ViewedLinks
import ViewedLinksMock

@Suite("ViewedLinksViewModel", .timeLimit(.minutes(1)))
@MainActor
struct ViewedLinksViewModelTests {
    // MARK: - Titles

    @Test("selectionTitle falls back to the select prompt when nothing is selected")
    func selectionTitleWithoutSelection() {
        let sut = makeSUT()

        #expect(sut.selectionTitle == Strings.Localizable.selectTitle)
    }

    @Test("selectionTitle counts the selected links")
    func selectionTitleWithSelection() throws {
        let sut = makeSUT(links: try links(handles: [1, 2]))

        sut.selectionDidChange([1, 2])

        #expect(sut.selectionTitle == Strings.Localizable.General.Format.itemsSelected(2))
    }

    @Test("clearSelectedLinksTitle uses the singular title for one link")
    func clearSelectedLinksTitleSingular() throws {
        let sut = makeSUT(links: try links(handles: [1]))

        sut.selectionDidChange([1])

        #expect(sut.clearSelectedLinksTitle == Strings.Localizable.ViewedLinks.ClearLink.Confirmation.title)
    }

    @Test("clearSelectedLinksTitle uses the plural title for several links")
    func clearSelectedLinksTitlePlural() throws {
        let sut = makeSUT(links: try links(handles: [1, 2]))

        sut.selectionDidChange([1, 2])

        #expect(sut.clearSelectedLinksTitle == Strings.Localizable.ViewedLinks.ClearLinks.Confirmation.title)
    }

    // MARK: - Requesting a confirmation

    @Test("requestClearSelectedLinks does nothing while nothing is selected")
    func requestClearSelectedLinksWithoutSelection() {
        let sut = makeSUT()

        sut.requestClearSelectedLinks()

        #expect(sut.isPresentingClearSelectedConfirmation == false)
    }

    @Test("requestClearSelectedLinks presents the confirmation once something is selected")
    func requestClearSelectedLinksWithSelection() throws {
        let sut = makeSUT(links: try links(handles: [1]))

        sut.selectionDidChange([1])
        sut.requestClearSelectedLinks()

        #expect(sut.isPresentingClearSelectedConfirmation)
        #expect(sut.isPresentingClearAllConfirmation == false)
    }

    @Test("requestClearAllLinks presents its own confirmation")
    func requestClearAllLinks() {
        let sut = makeSUT()

        sut.requestClearAllLinks()

        #expect(sut.isPresentingClearAllConfirmation)
        #expect(sut.isPresentingClearSelectedConfirmation == false)
    }

    // MARK: - Clearing the selection

    @Test("clearSelectedLinks removes only the selected links and keeps the screen open")
    func clearSelectedLinksRemovesSelection() async throws {
        let all = try links(handles: [1, 2, 3])
        let useCase = MockViewedLinksUseCase()
        let sut = makeSUT(useCase: useCase, links: all)

        sut.selectionDidChange([1, 2])
        let closesScreen = await sut.clearSelectedLinks()

        #expect(closesScreen == false)
        #expect(useCase.removedLinks.map { $0.map(\.handle).sorted() } == [[1, 2]])
        #expect(sut.clearedSnackBarMessage == nil)
    }

    @Test("clearSelectedLinks closes the screen when the selection covers every link")
    func clearSelectedLinksRemovesEverything() async throws {
        let all = try links(handles: [1, 2])
        let useCase = MockViewedLinksUseCase()
        let sut = makeSUT(useCase: useCase, links: all)

        sut.selectionDidChange([1, 2])
        let closesScreen = await sut.clearSelectedLinks()

        #expect(closesScreen)
        #expect(sut.clearedSnackBarMessage == Strings.Localizable.ViewedLinks.Clear.Success.message)
    }

    @Test("clearSelectedLinks does nothing while nothing is selected")
    func clearSelectedLinksWithoutSelection() async throws {
        let useCase = MockViewedLinksUseCase()
        let sut = makeSUT(useCase: useCase, links: try links(handles: [1]))

        let closesScreen = await sut.clearSelectedLinks()

        #expect(closesScreen == false)
        #expect(useCase.removedLinks.isEmpty)
    }

    @Test("clearSelectedLinks keeps the screen open when the store fails")
    func clearSelectedLinksWhenStoreFails() async throws {
        let all = try links(handles: [1])
        let useCase = MockViewedLinksUseCase(errorToThrow: .storeOperationFailed)
        let sut = makeSUT(useCase: useCase, links: all)

        sut.selectionDidChange([1])
        let closesScreen = await sut.clearSelectedLinks()

        #expect(closesScreen == false)
        #expect(sut.clearedSnackBarMessage == nil)
    }

    // MARK: - Clearing the history

    @Test("clearAllLinks clears the history and closes the screen")
    func clearAllLinksSucceeds() async {
        let useCase = MockViewedLinksUseCase()
        let sut = makeSUT(useCase: useCase)

        let closesScreen = await sut.clearAllLinks()

        #expect(closesScreen)
        #expect(useCase.clearHistoryCallCount == 1)
        #expect(sut.clearedSnackBarMessage == Strings.Localizable.ViewedLinks.Clear.Success.message)
    }

    @Test("clearAllLinks keeps the screen open when the store fails")
    func clearAllLinksWhenStoreFails() async {
        let useCase = MockViewedLinksUseCase(errorToThrow: .storeOperationFailed)
        let sut = makeSUT(useCase: useCase)

        let closesScreen = await sut.clearAllLinks()

        #expect(closesScreen == false)
        #expect(sut.clearedSnackBarMessage == nil)
    }

    // MARK: - Opening a link

    @Test("didSelect opens the link behind the selected row")
    func didSelectOpensLink() throws {
        let all = try links(handles: [1, 2])
        let opened = OpenedLinks()
        let sut = makeSUT(links: all, openLink: { opened.append($0) })

        sut.didSelect(try selection(for: all[1]))

        #expect(opened.urls == [all[1].linkURL])
    }

    @Test("didSelect ignores a row the provider does not know")
    func didSelectIgnoresUnknownRow() throws {
        let known = try links(handles: [1])
        let unknown = try link(handle: 9)
        let opened = OpenedLinks()
        let sut = makeSUT(links: known, openLink: { opened.append($0) })

        sut.didSelect(try selection(for: unknown))

        #expect(opened.urls.isEmpty)
    }

    // MARK: - Helpers

    @MainActor
    private final class OpenedLinks {
        private(set) var urls: [URL] = []

        func append(_ url: URL) {
            urls.append(url)
        }
    }

    private func makeSUT(
        useCase: MockViewedLinksUseCase = MockViewedLinksUseCase(),
        links: [ViewedLinkEntity] = [],
        openLink: @escaping @MainActor (URL) -> Void = { _ in }
    ) -> ViewedLinksViewModel {
        ViewedLinksViewModel(
            viewedLinksUseCase: useCase,
            resultsProvider: MockViewedLinksResultsProvider(links: links),
            openLink: openLink
        )
    }

    private func link(handle: UInt64) throws -> ViewedLinkEntity {
        ViewedLinkEntity(
            handle: handle,
            linkURL: try #require(URL(string: "https://mega.nz/file/\(handle)#key")),
            name: "file\(handle).jpg",
            isFolder: false,
            hasThumbnail: false,
            lastAccessed: Date(timeIntervalSince1970: TimeInterval(handle))
        )
    }

    private func links(handles: [UInt64]) throws -> [ViewedLinkEntity] {
        try handles.map { try link(handle: $0) }
    }

    private func selection(for entity: ViewedLinkEntity) throws -> SearchResultSelection {
        let result = ViewedLinkSearchResultMapper(thumbnailUseCase: MockViewedLinkThumbnailUseCase())
            .map(link: entity)

        return SearchResultSelection(result: result, siblingsProvider: { [] })
    }
}

import MEGAPDFSearchInterceptor
import MEGAPDFSearchInterceptorTestSupport
@testable import MEGAPDFViewer
import PDFKit
import Testing
import UIKit

/// Groups the suites that present a real Find navigator, so no two run at
/// once.
@Suite(.serialized)
@MainActor
struct FindNavigatorPresentationTests {}

extension FindNavigatorPresentationTests {
    @MainActor
    struct PDFViewSearchInteractionHandlerTests {
        @Test func presentSearch_opensSessionSearchingTheInterceptor() async throws {
            let (window, _, handler, interaction) = try makeAttachedHandler()
            defer { window.isHidden = true }

            handler.presentSearch()

            for _ in 0..<20 where interaction.activeFindSession == nil {
                try await Task.sleep(for: .milliseconds(100))
            }
            let session = try #require(interaction.activeFindSession as? UITextSearchingFindSession)
            #expect(session.searchableObject is MEGAPDFUITextSearchingFindSessionInterceptor)
            session.performSearch(query: "alpha", options: nil)
            for _ in 0..<20 where session.resultCount != 2 {
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(session.resultCount == 2)

            handler.dismissSearch()
            for _ in 0..<20 where interaction.isFindNavigatorVisible {
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(!interaction.isFindNavigatorVisible)

            handler.presentSearch()
            for _ in 0..<20 where !interaction.isFindNavigatorVisible {
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(interaction.isFindNavigatorVisible)
            handler.dismissSearch()
        }

        @Test func sessionFor_buildsNewSessionAndInterceptorEachTime() throws {
            let (window, pdfView, handler, interaction) = try makeAttachedHandler()
            defer { window.isHidden = true }

            let first = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            let second = try #require(handler.findInteraction(interaction, sessionFor: pdfView))

            #expect(first !== second)
            #expect(interceptor(of: first) !== interceptor(of: second))
        }

        @Test func detachedPDFView_sessionFor_returnsNil() {
            let frame = CGRect(x: 0, y: 0, width: 400, height: 700)
            let pdfView = PDFView(frame: frame)
            let data = UIGraphicsPDFRenderer(bounds: frame).pdfData { context in
                context.beginPage()
                "alpha beta".draw(at: CGPoint(x: 48, y: 48))
            }
            pdfView.document = PDFDocument(data: data)
            pdfView.layoutIfNeeded()
            let handler = PDFViewSearchInteractionHandler()
            handler.attachToPDFView(pdfView)
            let interaction = UIFindInteraction(sessionDelegate: handler)
            #expect(MEGAPDFUITextSearchingFindSessionInterceptor(
                pdfView: pdfView,
                documentSearcher: PDFDocumentSearcher(pdfView: pdfView),
                jumpToSearchResultScrollAdjuster: nil
            ) != nil)

            #expect(handler.findInteraction(interaction, sessionFor: pdfView) == nil)
        }

        @Test func session_keepsItsInterceptorAlive() throws {
            let (window, pdfView, handler, interaction) = try makeAttachedHandler()
            defer { window.isHidden = true }
            let session = try #require(handler.findInteraction(interaction, sessionFor: pdfView))

            handler.findInteraction(interaction, didEnd: session)

            #expect(interceptor(of: session) != nil)
        }

        @Test func sessionEnd_cancelsRunningSearch() throws {
            let (window, pdfView, handler, interaction) = try makeAttachedHandler()
            defer { window.isHidden = true }
            let session = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            _ = MEGARecordingSearchAggregator.performingQuery("alpha", on: try #require(interceptor(of: session)))
            #expect(pdfView.document?.isFinding == true)

            handler.findInteraction(interaction, didEnd: session)

            #expect(pdfView.document?.isFinding == false)
        }

        @Test func lateEndOfEarlierSession_leavesCurrentSearchRunning() throws {
            let (window, pdfView, handler, interaction) = try makeAttachedHandler()
            defer { window.isHidden = true }
            let earlierSession = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            let currentSession = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            _ = MEGARecordingSearchAggregator.performingQuery(
                "alpha",
                on: try #require(interceptor(of: currentSession))
            )

            handler.findInteraction(interaction, didEnd: earlierSession)
            #expect(pdfView.document?.isFinding == true)

            handler.findInteraction(interaction, didEnd: currentSession)
            #expect(pdfView.document?.isFinding == false)
        }

        @Test func repeatedEndOfSession_leavesNextSearchRunning() throws {
            let (window, pdfView, handler, interaction) = try makeAttachedHandler()
            defer { window.isHidden = true }
            let earlierSession = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            handler.findInteraction(interaction, didEnd: earlierSession)
            let currentSession = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            _ = MEGARecordingSearchAggregator.performingQuery(
                "alpha",
                on: try #require(interceptor(of: currentSession))
            )

            handler.findInteraction(interaction, didEnd: earlierSession)

            #expect(pdfView.document?.isFinding == true)
        }

        @Test func sessionCallbacks_reportCurrentSessionBeginAndEndOnce() throws {
            let (window, pdfView, handler, interaction) = try makeAttachedHandler()
            defer { window.isHidden = true }
            var begunSessionIDs: [UUID] = []
            var endedSessionIDs: [UUID] = []
            handler.onSearchSessionDidBegin = { begunSessionIDs.append($0) }
            handler.onSearchSessionDidEnd = { endedSessionIDs.append($0) }
            let earlierSession = try #require(
                handler.findInteraction(interaction, sessionFor: pdfView) as? PDFViewFindSession
            )
            let currentSession = try #require(
                handler.findInteraction(interaction, sessionFor: pdfView) as? PDFViewFindSession
            )

            handler.findInteraction(interaction, didBegin: currentSession)
            handler.findInteraction(interaction, didEnd: earlierSession)
            handler.findInteraction(interaction, didEnd: currentSession)
            handler.findInteraction(interaction, didEnd: currentSession)

            #expect(begunSessionIDs == [currentSession.analyticsID])
            #expect(endedSessionIDs == [currentSession.analyticsID])
        }

        @Test func overlappingSessions_keepOneKeyboardInsetUntilCurrentSessionEnds() async throws {
            let notificationCenter = NotificationCenter()
            let (window, pdfView, handler, interaction) = try makeAttachedHandler(
                notificationCenter: notificationCenter
            )
            defer { window.isHidden = true }
            let scrollView = try #require(pdfView.contentScrollView)
            let insetWithoutKeyboard = scrollView.contentInset.bottom
            let earlierSession = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            try await jumpWithKeyboardUp(
                in: earlierSession, scrollView: scrollView, notificationCenter: notificationCenter
            )
            let insetWithKeyboard = scrollView.contentInset.bottom
            #expect(insetWithKeyboard > insetWithoutKeyboard)

            let currentSession = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            #expect(scrollView.contentInset.bottom == insetWithKeyboard)
            try await jumpToFirstResult(in: currentSession)
            #expect(scrollView.contentInset.bottom == insetWithKeyboard)
            handler.findInteraction(interaction, didEnd: earlierSession)
            #expect(scrollView.contentInset.bottom == insetWithKeyboard)

            handler.findInteraction(interaction, didEnd: currentSession)
            #expect(scrollView.contentInset.bottom == insetWithoutKeyboard)
        }

        @Test func newSessionWithKeyboardStillUp_jumpAddsKeyboardInset() async throws {
            let notificationCenter = NotificationCenter()
            let (window, pdfView, handler, interaction) = try makeAttachedHandler(
                notificationCenter: notificationCenter
            )
            defer { window.isHidden = true }
            let scrollView = try #require(pdfView.contentScrollView)
            let insetWithoutKeyboard = scrollView.contentInset.bottom
            let earlierSession = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            try await jumpWithKeyboardUp(
                in: earlierSession, scrollView: scrollView, notificationCenter: notificationCenter
            )
            handler.findInteraction(interaction, didEnd: earlierSession)

            let currentSession = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            try await jumpToFirstResult(in: currentSession)

            #expect(scrollView.contentInset.bottom > insetWithoutKeyboard)
        }

        @Test func reopenedSession_reportsOnlyItsOwnQuery() async throws {
            let (window, pdfView, handler, interaction) = try makeAttachedHandler(pageCount: 300)
            defer { window.isHidden = true }
            do {
                let firstSession = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
                _ = MEGARecordingSearchAggregator.performingQuery(
                    "ipsum",
                    on: try #require(interceptor(of: firstSession))
                )
                try await Task.sleep(for: .milliseconds(20))
                handler.findInteraction(interaction, didEnd: firstSession)
            }

            let secondSession = try #require(handler.findInteraction(interaction, sessionFor: pdfView))
            let aggregator = MEGARecordingSearchAggregator.performingQuery(
                "beta",
                on: try #require(interceptor(of: secondSession))
            )
            for _ in 0..<50 where !aggregator.didFinishSearching {
                try await Task.sleep(for: .milliseconds(100))
            }

            #expect(aggregator.didFinishSearching)
            #expect(aggregator.foundRangeCount == 300)
        }

        @Test func newDocument_doesNotRestorePreviousDocumentQuery() async throws {
            let frame = CGRect(x: 0, y: 0, width: 400, height: 700)
            let window = UIWindow(frame: frame)
            let root = UIViewController()
            window.rootViewController = root
            window.makeKeyAndVisible()
            defer { window.isHidden = true }
            let data = UIGraphicsPDFRenderer(bounds: frame).pdfData { context in
                context.beginPage()
                "test tested".draw(at: CGPoint(x: 48, y: 48))
            }
            let firstView = PDFView(frame: frame)
            root.view.addSubview(firstView)
            firstView.document = PDFDocument(data: data)
            firstView.layoutIfNeeded()
            let firstHandler = PDFViewSearchInteractionHandler()
            firstHandler.attachToPDFView(firstView)
            let firstInteraction = try #require(
                firstView.interactions.compactMap { $0 as? UIFindInteraction }.first
            )
            firstInteraction.searchText = "test"
            firstHandler.presentSearch()
            try await Task.sleep(for: .milliseconds(500))
            firstInteraction.dismissFindNavigator()
            try await Task.sleep(for: .milliseconds(500))
            firstView.removeFromSuperview()

            let secondView = PDFView(frame: frame)
            root.view.addSubview(secondView)
            secondView.document = PDFDocument(data: data)
            secondView.layoutIfNeeded()
            let secondHandler = PDFViewSearchInteractionHandler()
            secondHandler.attachToPDFView(secondView)
            secondHandler.presentSearch()
            try await Task.sleep(for: .milliseconds(500))
            let secondInteraction = try #require(
                secondView.interactions.compactMap { $0 as? UIFindInteraction }.first
            )
            defer { secondInteraction.dismissFindNavigator() }
            #expect(secondInteraction.searchText == "")
            #expect(secondInteraction.activeFindSession?.resultCount == 0)
        }

        @Test func missingSearchableView_presentsPDFKitsOwnFind() async throws {
            var reportCount = 0
            let (window, pdfView, handler, _) = try makeAttachedHandler(
                handler: PDFViewSearchInteractionHandler(
                    makeInterceptor: { _, _, _ in nil },
                    reportMissingSearchableView: { reportCount += 1 }
                )
            )
            defer { window.isHidden = true }

            handler.presentSearch()
            for _ in 0..<20 where !pdfView.findInteraction.isFindNavigatorVisible {
                try await Task.sleep(for: .milliseconds(100))
            }

            #expect(reportCount == 1)
            #expect(pdfView.findInteraction.isFindNavigatorVisible)

            handler.dismissSearch()
            for _ in 0..<20 where pdfView.findInteraction.isFindNavigatorVisible {
                try await Task.sleep(for: .milliseconds(100))
            }

            #expect(!pdfView.findInteraction.isFindNavigatorVisible)
        }

        @Test func searchableViewFound_keepsPDFKitsOwnFindDisabled() throws {
            var reportCount = 0
            let (window, pdfView, handler, _) = try makeAttachedHandler(
                handler: PDFViewSearchInteractionHandler(
                    reportMissingSearchableView: { reportCount += 1 }
                )
            )
            defer {
                handler.dismissSearch()
                window.isHidden = true
            }

            handler.presentSearch()

            #expect(reportCount == 0)
            #expect(!pdfView.isFindInteractionEnabled)
        }

        @Test func findNavigatorOptionsMenu_offersMatchCaseOnly() async throws {
            let (window, _, handler, interaction) = try makeAttachedHandler()
            defer {
                handler.dismissSearch()
                window.isHidden = true
            }
            let provider = try #require(interaction.optionsMenuProvider)
            var defaultOptionIdentifiers = [String]()
            interaction.optionsMenuProvider = { defaultOptions in
                defaultOptionIdentifiers = actionIdentifiers(in: defaultOptions)
                return provider(defaultOptions)
            }
            handler.presentSearch()
            for _ in 0..<20 where !interaction.isFindNavigatorVisible {
                try await Task.sleep(for: .milliseconds(100))
            }

            let menu = try optionsMenu(of: interaction)

            #expect(defaultOptionIdentifiers.contains("matchCase"))
            #expect(defaultOptionIdentifiers.contains("wholeWords"))
            #expect(actionIdentifiers(in: menu.children) == ["matchCase"])
        }

        @Test func optionsMenu_leavesOutWholeWords() throws {
            let (window, _, handler, interaction) = try makeAttachedHandler()
            defer { window.isHidden = true }
            let provider = try #require(interaction.optionsMenuProvider)
            let menu = try withExtendedLifetime(handler) {
                try #require(provider([
                    UIAction(title: "Match Case", identifier: .init("matchCase")) { _ in },
                    UIAction(title: "Whole Words", identifier: .init("wholeWords")) { _ in }
                ]))
            }

            #expect(menu.children.compactMap { ($0 as? UIAction)?.identifier.rawValue } == ["matchCase"])
        }

        @Test func newDocument_resetsOptionsAndSearchHonorsMatchCaseToggle() async throws {
            let frame = CGRect(x: 0, y: 0, width: 400, height: 700)
            let window = UIWindow(frame: frame)
            let root = UIViewController()
            window.rootViewController = root
            window.makeKeyAndVisible()
            defer { window.isHidden = true }
            let pdfView = PDFView(frame: frame)
            root.view.addSubview(pdfView)
            let data = UIGraphicsPDFRenderer(bounds: frame).pdfData { context in
                context.beginPage()
                "pill Pill PILL".draw(at: CGPoint(x: 48, y: 48))
            }
            pdfView.document = PDFDocument(data: data)
            pdfView.layoutIfNeeded()
            let handler = PDFViewSearchInteractionHandler()
            handler.attachToPDFView(pdfView)
            let interaction = try #require(
                pdfView.interactions.compactMap { $0 as? UIFindInteraction }.first
            )
            let provider = try #require(interaction.optionsMenuProvider)
            var nativeActionCallCount = 0
            let nativeCaseAction = UIAction(
                title: "Match Case", identifier: .init("matchCase"), state: .on
            ) { _ in nativeActionCallCount += 1 }
            let nativeWordAction = UIAction(
                title: "Whole Words", identifier: .init("wholeWords"), state: .on
            ) { _ in }
            let defaultOptions: [UIMenuElement] = [nativeCaseAction, nativeWordAction]
            let initialMenu = try #require(provider(defaultOptions))
            let initialActions = initialMenu.children.compactMap { $0 as? UIAction }
            #expect(initialActions.map(\.state) == [.off])

            handler.presentSearch()
            for _ in 0..<20 where interaction.activeFindSession == nil {
                try await Task.sleep(for: .milliseconds(100))
            }
            let session = try #require(interaction.activeFindSession)
            defer { interaction.dismissFindNavigator() }
            session.performSearch(query: "pill", options: UITextSearchOptions())
            for _ in 0..<20 where session.resultCount != 3 {
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(session.resultCount == 3)

            UIControl().sendAction(try #require(initialActions.first))
            #expect(nativeActionCallCount == 1)
            let selectedMenu = try #require(provider(defaultOptions))
            #expect((selectedMenu.children.first as? UIAction)?.state == .on)
            session.performSearch(query: "pill", options: UITextSearchOptions())
            for _ in 0..<20 where session.resultCount != 1 {
                try await Task.sleep(for: .milliseconds(100))
            }
            #expect(session.resultCount == 1)

            let nextView = PDFView(frame: frame)
            let nextHandler = PDFViewSearchInteractionHandler()
            nextHandler.attachToPDFView(nextView)
            let nextInteraction = try #require(
                nextView.interactions.compactMap { $0 as? UIFindInteraction }.first
            )
            let nextProvider = try #require(nextInteraction.optionsMenuProvider)
            let nextMenu = try #require(nextProvider(defaultOptions))
            #expect(nextMenu.children.compactMap { ($0 as? UIAction)?.state } == [.off])
        }

        @Test func nativeFindNavigation_reportsSessionAndDistinctResultPositions() async throws {
            let (window, _, handler, interaction) = try makeAttachedHandler()
            defer { window.isHidden = true }
            var sessions: [UUID] = []
            var results: [(UUID, UUID, Int)] = []
            handler.onSearchSessionDidBegin = { sessions.append($0) }
            handler.onSearchResultChanged = { results.append(($0, $1, $2)) }
            handler.presentSearch()
            for _ in 0..<20 where interaction.activeFindSession == nil {
                try await Task.sleep(for: .milliseconds(100))
            }
            let session = try #require(interaction.activeFindSession)
            defer { handler.dismissSearch() }
            session.performSearch(query: "alpha", options: nil)
            for _ in 0..<20 where session.resultCount != 2 {
                try await Task.sleep(for: .milliseconds(100))
            }
            try #require(session.resultCount == 2)
            if session.highlightedResultIndex == NSNotFound {
                session.highlightNextResult(in: .forward)
            }
            let initial = session.highlightedResultIndex
            try #require(initial != NSNotFound)
            results.removeAll()
            session.highlightNextResult(in: .forward)
            let next = session.highlightedResultIndex
            session.highlightNextResult(in: .backward)

            #expect(next != initial)
            #expect(session.highlightedResultIndex == initial)
            #expect(sessions.count == 1)
            #expect(results.map { $0.2 } == [initial, next, next, initial])
            #expect(Set(results.map { $0.0 }) == Set(sessions))
            #expect(Set(results.map { $0.1 }).count == 1)
        }

        private func jumpToFirstResult(in session: UIFindSession) async throws {
            let sessionInterceptor = try #require(interceptor(of: session))
            let aggregator = MEGARecordingSearchAggregator.performingQuery(
                "alpha",
                on: sessionInterceptor
            )
            for _ in 0..<50 where !aggregator.didFinishSearching {
                try await Task.sleep(for: .milliseconds(50))
            }
            aggregator.scrollToRange(at: 0, on: sessionInterceptor)
        }

        private func jumpWithKeyboardUp(
            in session: UIFindSession,
            scrollView: UIScrollView,
            notificationCenter: NotificationCenter
        ) async throws {
            let insetWithoutKeyboard = scrollView.contentInset.bottom
            let userInfo = [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(
                    cgRect: CGRect(x: 0, y: 400, width: 400, height: 300)
                )
            ]
            // The adjuster subscribes from a `Task`, so a single post can
            // arrive before the subscription exists.
            for _ in 0..<100 where scrollView.contentInset.bottom == insetWithoutKeyboard {
                notificationCenter.post(
                    name: UIResponder.keyboardDidShowNotification, object: nil, userInfo: userInfo
                )
                notificationCenter.post(
                    name: UIResponder.keyboardDidChangeFrameNotification,
                    object: nil,
                    userInfo: userInfo
                )
                await Task.yield()
                try await jumpToFirstResult(in: session)
            }
        }

        private func makeAttachedHandler(
            pageCount: Int = 2,
            notificationCenter: NotificationCenter = NotificationCenter(),
            handler: PDFViewSearchInteractionHandler? = nil
        ) throws -> (
            UIWindow, PDFView, PDFViewSearchInteractionHandler, UIFindInteraction
        ) {
            let frame = CGRect(x: 0, y: 0, width: 400, height: 700)
            let window = UIWindow(frame: frame)
            let root = UIViewController()
            window.rootViewController = root
            window.makeKeyAndVisible()
            let pdfView = PDFView(frame: frame)
            root.view.addSubview(pdfView)
            let data = UIGraphicsPDFRenderer(bounds: frame).pdfData { context in
                // Filler keeps a search of many pages running long enough for a
                // second search to start before it ends.
                let filler = String(repeating: "lorem ipsum dolor sit amet ", count: 60)
                for _ in 0..<pageCount {
                    context.beginPage()
                    ("alpha beta " + filler).draw(in: frame.insetBy(dx: 24, dy: 24))
                }
            }
            pdfView.document = PDFDocument(data: data)
            pdfView.layoutIfNeeded()
            let handler = handler
                ?? PDFViewSearchInteractionHandler(notificationCenter: notificationCenter)
            handler.attachToPDFView(pdfView)
            let interaction = try #require(
                pdfView.interactions.compactMap { $0 as? UIFindInteraction }.first
            )
            return (window, pdfView, handler, interaction)
        }

        private func optionsMenu(of interaction: UIFindInteraction) throws -> UIMenu {
            // UIKit calls `optionsMenuProvider` only when the options button
            // of the Find navigator opens its menu, which these private
            // members of the navigator reach.
            let controller = try privateObject("_currentFindNavigatorController", of: interaction)
            let navigatorView = try #require(
                privateObject("findNavigatorView", of: controller) as? UIView
            )
            let optionsButton = try #require(
                subviews(of: navigatorView)
                    .compactMap { $0 as? UIButton }
                    .first { $0.showsMenuAsPrimaryAction }
            )
            let menuInteraction = try #require(
                optionsButton.interactions.compactMap { $0 as? UIContextMenuInteraction }.first
            )
            let configuration = try #require(menuInteraction.delegate?.contextMenuInteraction(
                menuInteraction,
                configurationForMenuAtLocation: .zero
            ))
            try #require(configuration.responds(to: NSSelectorFromString("actionProvider")))
            let actionProvider = try #require(configuration.value(forKey: "actionProvider"))
            typealias ActionProvider = @convention(block) (NSArray) -> UIMenu?
            let makeMenu = unsafeBitCast(actionProvider as AnyObject, to: ActionProvider.self)
            return try #require(makeMenu([]))
        }

        private func privateObject(_ selectorName: String, of object: NSObject) throws -> NSObject {
            let selector = NSSelectorFromString(selectorName)
            try #require(object.responds(to: selector))
            return try #require(object.perform(selector)?.takeUnretainedValue() as? NSObject)
        }

        private func subviews(of view: UIView) -> [UIView] {
            view.subviews.flatMap { [$0] + subviews(of: $0) }
        }

        private func actionIdentifiers(in elements: [UIMenuElement]) -> [String] {
            elements.flatMap { element -> [String] in
                if let menu = element as? UIMenu { return actionIdentifiers(in: menu.children) }
                return (element as? UIAction).map { [$0.identifier.rawValue] } ?? []
            }
        }

        private func interceptor(
            of session: UIFindSession
        ) -> MEGAPDFUITextSearchingFindSessionInterceptor? {
            (session as? UITextSearchingFindSession)?.searchableObject
                as? MEGAPDFUITextSearchingFindSessionInterceptor
        }
    }
}

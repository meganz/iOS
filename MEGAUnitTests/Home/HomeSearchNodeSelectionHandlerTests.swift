@testable import MEGA
import MEGAAppPresentation
import MEGADomain
import Testing

@MainActor
struct HomeSearchNodeSelectionHandlerTests {
    @Test func fileTappedInSearchResults_opensAsSearch() {
        let router = MockNodeRouter()

        HomeSearchNodeSelectionHandler(nodeRouter: router)
            .handle(selection: NodeSelection(handle: 1, siblings: [], isSearchActive: true, isFolder: false))

        #expect(router.sourcePages == [.search])
    }

    @Test func folderTappedInSearchResults_doesNotOpenAsSearch() {
        let router = MockNodeRouter()

        HomeSearchNodeSelectionHandler(nodeRouter: router)
            .handle(selection: NodeSelection(handle: 1, siblings: [], isSearchActive: true, isFolder: true))

        #expect(router.sourcePages == [.unknown])
    }

    @Test(arguments: [true, false])
    func nodeTappedOutsideSearch_opensAsUnknown(isFolder: Bool) {
        let router = MockNodeRouter()

        HomeSearchNodeSelectionHandler(nodeRouter: router)
            .handle(selection: NodeSelection(handle: 1, siblings: [], isSearchActive: false, isFolder: isFolder))

        #expect(router.sourcePages == [.unknown])
    }
}

@MainActor
private final class MockNodeRouter: NodeRouting {
    private(set) var sourcePages: [NodeSourcePage] = []

    func didTapMoreAction(on node: HandleEntity, button: UIButton, isFromSharedItem: Bool) {}

    func didTapMoreAction(on node: HandleEntity, button: UIButton, displayMode: DisplayMode?, isFromSharedItem: Bool) {}

    func didTapNode(nodeHandle: HandleEntity, allNodeHandles: [HandleEntity]?, displayMode: DisplayMode?, sourcePage: NodeSourcePage, isFromSharedItem: Bool, warningViewModel: WarningBannerViewModel?) {
        sourcePages.append(sourcePage)
    }

    func didTapNode(nodeHandle: HandleEntity, resolvedNode: NodeEntity?, allNodeHandles: [HandleEntity]?, displayMode: DisplayMode?, sourcePage: NodeSourcePage, isFromSharedItem: Bool, warningViewModel: WarningBannerViewModel?) {
        sourcePages.append(sourcePage)
    }

    func didTapNode(nodeHandle: HandleEntity, allNodeHandles: [HandleEntity]?, sourcePage: NodeSourcePage) {
        sourcePages.append(sourcePage)
    }

    func didTapNode(nodeHandle: HandleEntity, sourcePage: NodeSourcePage) {
        sourcePages.append(sourcePage)
    }
}

@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPresentation
import MEGAPresentationMock
import MEGASDKRepo
import MEGASDKRepoMock
import MEGATest
import XCTest

final class GetNodeLinkViewModelTests: XCTestCase {
    
    @MainActor func testDispatch_onViewReadyAndAllNodeExported_returnCorrectCommands() {
        for hiddenNodesFeatureFlagActive in [true, false] {
            
            let nodes: [MEGANode] = [
                MockNode(handle: 1, isNodeExported: true)
            ]
            let sut = sut(nodes: nodes,
                          hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            let expectedTitle = Strings.Localizable.General.MenuAction.ManageLink.title(nodes.count)
            
            test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(
                    title: expectedTitle,
                    isMultilink: false,
                    shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(nodes.count)),
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .enableLinkActions,
                .dismissHud,
                .processNodes
            ], expectationValidation: ==)
        }
    }
    
    @MainActor func testDispatch_onViewReadyAndSomeNodesNotExported_returnCorrectCommands() {
        for hiddenNodesFeatureFlagActive in [true, false] {
            
            let nodes: [MEGANode] = [
                MockNode(handle: 1, isNodeExported: true),
                MockNode(handle: 2, isNodeExported: false)
            ]
            let sut = sut(nodes: nodes,
                          hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            let expectedTitle = Strings.Localizable.General.MenuAction.ShareLink.title(nodes.count)
            
            test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(
                    title: expectedTitle,
                    isMultilink: true,
                    shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(nodes.count)),
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .enableLinkActions,
                .dismissHud,
                .processNodes
            ], expectationValidation: ==)
        }
    }
    
    @MainActor func testDispatch_onViewReadyAndNodeContainsSensitiveDescendant_returnCorrectCommands() {
        let nodes: [MEGANode] = [
            MockNode(handle: 1, isNodeExported: true),
            MockNode(handle: 2, isNodeExported: false)
        ]
        
        let sut = sut(
            nodes: nodes,
            shareUseCase: MockShareUseCase(containsSensitiveContent: [nodes[1].handle: true]),
            hiddenNodesFeatureFlagActive: true
        )
        
        let expectedTitle = Strings.Localizable.General.MenuAction.ShareLink.title(nodes.count)

        test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
            .configureView(
                title: expectedTitle,
                isMultilink: true,
                shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(nodes.count)),
            .showHud(.status(Strings.Localizable.generatingLinks)),
            .dismissHud,
            .showAlert(AlertModel(
                title: Strings.Localizable.GetNodeLink.Sensitive.Alert.title,
                message: Strings.Localizable.GetNodeLink.Sensitive.Alert.Message.multi,
                actions: [
                    .init(title: Strings.Localizable.cancel, style: .cancel, handler: { }),
                    .init(title: Strings.Localizable.continue, style: .default, isPreferredAction: true, handler: { })
                ]))
        ], expectationValidation: ==)
    }
    
    @MainActor
    func testDispatch_onViewReadyAndNodeContainsSensitiveDescendantAndTapsContinueOnAlert_returnCorrectCommands() {
        let nodes: [MEGANode] = [
            MockNode(handle: 1, isNodeExported: true),
            MockNode(handle: 2, isNodeExported: false)
        ]
        
        let sut = sut(
            nodes: nodes,
            shareUseCase: MockShareUseCase(containsSensitiveContent: [nodes[1].handle: true]),
            hiddenNodesFeatureFlagActive: true
        )
        
        let expectation = expectation(description: "Expect sensitive content alert to appear")
        var continueAction: AlertModel.AlertAction?
        sut.invokeCommand = {
            if case let .showAlert(alertModel) = $0,
               let action = alertModel.actions.first(where: { $0.title ==  Strings.Localizable.continue }) {
                continueAction = action
                expectation.fulfill()
            }
        }
        
        sut.dispatch(.onViewDidAppear)
        
        wait(for: [expectation], timeout: 1)
        
        test(viewModel: sut, trigger: { continueAction?.handler() }, expectedCommands: [
            .showHud(.status(Strings.Localizable.generatingLinks)),
            .enableLinkActions,
            .dismissHud,
            .processNodes
        ], expectationValidation: ==)
    }
    
    @MainActor
    func testDispatch_onViewReadyAndNodeContainsSensitiveDescendantAndTapsCancelOnAlert_returnCorrectCommands() {
        let nodes: [MEGANode] = [
            MockNode(handle: 1, isNodeExported: true),
            MockNode(handle: 2, isNodeExported: false)
        ]
        
        let sut = sut(
            nodes: nodes,
            shareUseCase: MockShareUseCase(containsSensitiveContent: [nodes[1].handle: true]),
            hiddenNodesFeatureFlagActive: true
        )
        
        let expectation = expectation(description: "Expect sensitive content alert to appear")
        var cancelAction: AlertModel.AlertAction?
        sut.invokeCommand = {
            if case let .showAlert(alertModel) = $0,
               let action = alertModel.actions.first(where: { $0.title ==  Strings.Localizable.cancel }) {
                cancelAction = action
                expectation.fulfill()
            }
        }
        
        sut.dispatch(.onViewDidAppear)

        wait(for: [expectation], timeout: 1)
        
        test(viewModel: sut, trigger: { cancelAction?.handler() }, expectedCommands: [
            .dismiss
        ], expectationValidation: ==)
    }
    
    @MainActor
    func testLinkWithoutKey_shouldReturnExpectedLink() {
        
        let scenarios = [
            ("https://mega.nz/file/link#key", "https://mega.nz/file/link"),
            ("https://mega.nz/folder/link#key", "https://mega.nz/folder/link"),
            ("https://mega.nz/file/link%key", "https://mega.nz/file/link%key"),
            ("https://mega.nz/unknown/link!link2!key", "https://mega.nz/unknown/link!link2"),
            ("#", "#")
        ]
        
        for (link, expectedValue) in scenarios {
            let sut = sut()
            sut.link = link
            XCTAssertEqual(sut.linkWithoutKey, expectedValue)
        }
    }
    
    @MainActor
    func testKey_shouldReturnExpectedKey() {
        
        let scenarios = [
            ("https://mega.nz/file/link#key", "key"),
            ("https://mega.nz/folder/link#key", "key"),
            ("https://mega.nz/file/link%key", ""),
            ("https://mega.nz/unknown/link!link2!key", "key"),
            ("https://mega.nz/unknown/link!key", ""),
            ("!", "")
        ]
        
        for (link, expectedValue) in scenarios {
            let sut = sut()
            sut.link = link
            XCTAssertEqual(sut.key, expectedValue)
        }
    }
}

extension GetNodeLinkViewModelTests {
    @MainActor
    private func sut(nodes: [MEGANode] = [],
                     shareUseCase: some ShareUseCaseProtocol = MockShareUseCase(),
                     hiddenNodesFeatureFlagActive: Bool = false
    ) -> GetNodeLinkViewModel {
        let sut = GetNodeLinkViewModel(
            shareUseCase: shareUseCase,
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(
                list: [.hiddenNodes: hiddenNodesFeatureFlagActive]))
        sut.nodes = nodes
        return sut
    }
}

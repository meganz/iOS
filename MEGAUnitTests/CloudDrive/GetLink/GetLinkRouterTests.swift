@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import MEGAShareLink
import SwiftUI
import Testing

@MainActor
@Suite("GetLinkRouter")
struct GetLinkRouterTests {
    private typealias ShareLinkHostingController = MEGAShareLink.ShareLinkHostingController<EnforceCopyrightWarningView<ShareLinkView>>

    @Test("with both flags on, start presents the Share link screen behind the copyright gate")
    func start_bothFlagsOn_presentsShareLinkScreen() throws {
        let (sut, presenter) = makeSUT(isLocalFlagOn: true, isRemoteFlagOn: true)

        sut.start()

        #expect(try presentedController(of: presenter) is ShareLinkHostingController)
    }

    @Test(
        "unless both flags are on, start presents the legacy screen with the default style",
        arguments: [(true, false), (false, true), (false, false)]
    )
    func start_eitherFlagOff_presentsLegacyScreen(flags: (isLocalFlagOn: Bool, isRemoteFlagOn: Bool)) throws {
        let (sut, presenter) = makeSUT(isLocalFlagOn: flags.isLocalFlagOn, isRemoteFlagOn: flags.isRemoteFlagOn)

        sut.start()

        let presented = try presentedController(of: presenter)
        #expect(!(presented is ShareLinkHostingController))
        #expect(presented.modalPresentationStyle == UIViewController().modalPresentationStyle)
    }

    @Test("with both flags on and no connection, start shows the no-connection prompt and presents nothing")
    func start_bothFlagsOnAndUnreachable_presentsNothing() {
        var reachabilityCheckCount = 0
        let (sut, presenter) = makeSUT(isLocalFlagOn: true, isRemoteFlagOn: true) {
            reachabilityCheckCount += 1
            return false
        }

        sut.start()

        #expect(reachabilityCheckCount == 1)
        #expect(presenter.messages.isEmpty)
    }

    @Test(
        "unless both flags are on, start presents the legacy screen without checking the connection",
        arguments: [(true, false), (false, true), (false, false)]
    )
    func start_eitherFlagOffAndUnreachable_presentsLegacyScreen(flags: (isLocalFlagOn: Bool, isRemoteFlagOn: Bool)) throws {
        var reachabilityCheckCount = 0
        let (sut, presenter) = makeSUT(isLocalFlagOn: flags.isLocalFlagOn, isRemoteFlagOn: flags.isRemoteFlagOn) {
            reachabilityCheckCount += 1
            return false
        }

        sut.start()

        #expect(reachabilityCheckCount == 0)
        #expect(!(try presentedController(of: presenter) is ShareLinkHostingController))
    }

    private func makeSUT(
        isLocalFlagOn: Bool,
        isRemoteFlagOn: Bool,
        isReachablePromptingIfNot: @escaping () -> Bool = { true }
    ) -> (sut: GetLinkRouter, presenter: MockNavigationController) {
        let presenter = MockNavigationController()
        let sut = GetLinkRouter(
            presenter: presenter,
            nodes: [MockNode(handle: 1)],
            featureFlagProvider: MockFeatureFlagProvider(list: [.shareLinkRevamp: isLocalFlagOn]),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.iosShareLinkRevamp: isRemoteFlagOn]),
            isReachablePromptingIfNot: isReachablePromptingIfNot
        )
        return (sut, presenter)
    }

    private func presentedController(of presenter: MockNavigationController) throws -> UIViewController {
        try #require(presenter.messages.compactMap { message -> UIViewController? in
            guard case .present(let viewController) = message else { return nil }
            return viewController
        }.first)
    }
}

@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

@MainActor
final class ShareExtensionCancellableTransferRouterTests: XCTestCase {

    /// The alert on screen only holds the wrapper weakly, so a second `build()` would free the
    /// wrapper and its view model, and the Cancel button would dispatch nothing.
    func testShowTransfersAlert_afterBuild_keepsTheBuiltViewModelAlive() {
        let presenter = UIViewController()
        let sut = ShareExtensionCancellableTransferRouter(presenter: presenter, transfers: [])
        weak var builtViewModel: ShareExtensionCancellableTransferViewModel?
        var viewModel: ShareExtensionCancellableTransferViewModel? = installViewModel(on: sut)
        builtViewModel = viewModel
        viewModel = nil

        sut.showTransfersAlert()

        XCTAssertNotNil(builtViewModel)
    }

    // MARK: - Helpers

    private func installViewModel(on router: ShareExtensionCancellableTransferRouter) -> ShareExtensionCancellableTransferViewModel {
        let viewModel = ShareExtensionCancellableTransferViewModel(
            router: router,
            uploadFileUseCase: MockUploadFileUseCase(),
            transfers: [])
        _ = router.build(viewModel: viewModel)
        return viewModel
    }
}

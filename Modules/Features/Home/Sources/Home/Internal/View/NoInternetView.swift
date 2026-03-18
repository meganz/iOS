import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGASwiftUI
import SwiftUI

@MainActor
final class NoInternetViewViewModel {
    private let homeViewRouter: any HomeViewRouting
    private let offlineFilesUseCase: any OfflineFilesUseCaseProtocol

    init(
        homeViewRouter: some HomeViewRouting,
        offlineFilesUseCase: some OfflineFilesUseCaseProtocol
    ) {
        self.offlineFilesUseCase = offlineFilesUseCase
        self.homeViewRouter = homeViewRouter
    }

    private var hasOfflineFiles: Bool {
        offlineFilesUseCase.offlineFiles().isNotEmpty
    }

    var viewOfflinesActions: [ContentUnavailableViewModel.ButtonAction] {
        hasOfflineFiles ? [ContentUnavailableViewModel.ButtonAction(
            title: "View Offline files",
            image: nil,
            handler: { [weak self] in
                self?.homeViewRouter.route(to: .offline)
            }
        )
        ]
        : []
    }
}

struct NoInternetView: View {
    struct Dependency {
        let homeViewRouter: any HomeViewRouting
        let offlineFilesUseCase: any OfflineFilesUseCaseProtocol
    }

    let viewModel: NoInternetViewViewModel
    init(dependency: Dependency) {
        viewModel = .init(homeViewRouter: dependency.homeViewRouter, offlineFilesUseCase: dependency.offlineFilesUseCase)
    }

    var body: some View {
        RevampedContentUnavailableView(
            viewModel: .init(
                image: MEGAAssets.Image.glassNoCloud,
                title: "You're offline",
                subtitle: "If you make files available offline, you’ll still be able to access them without a connection.",
                font: .callout,
                titleTextColor: TokenColors.Text.secondary.swiftUI,
                actions: viewModel.viewOfflinesActions
            )
        )
    }
}

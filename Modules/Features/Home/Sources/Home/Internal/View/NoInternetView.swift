import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import SwiftUI

@MainActor
final class NoInternetViewViewModel {
    private let homeViewRouter: any HomeViewRouting
    private let offlineFilesUseCase: any OfflineFilesUseCaseProtocol

    private var hasOfflineFiles: Bool {
        offlineFilesUseCase.offlineFiles().isNotEmpty
    }
    init(
        homeViewRouter: some HomeViewRouting,
        offlineFilesUseCase: some OfflineFilesUseCaseProtocol
    ) {
        self.offlineFilesUseCase = offlineFilesUseCase
        self.homeViewRouter = homeViewRouter
    }

    var title: String {
        Strings.Localizable.Home.NoInternet.title
    }

    var subtitle: String {
        hasOfflineFiles
        ? Strings.Localizable.Home.NoInternet.Subtitle.hasOfflineFiles
        : Strings.Localizable.Home.NoInternet.Subtitle.noOfflineFiles
    }

    var viewOfflinesActions: [ContentUnavailableViewModel.ButtonAction] {
        hasOfflineFiles ? [ContentUnavailableViewModel.ButtonAction(
            title: Strings.Localizable.Home.NoInternet.viewOfflineFiles,
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
                title: viewModel.title,
                subtitle: viewModel.subtitle,
                font: .callout,
                titleTextColor: TokenColors.Text.secondary.swiftUI,
                actions: viewModel.viewOfflinesActions
            )
        )
    }
}

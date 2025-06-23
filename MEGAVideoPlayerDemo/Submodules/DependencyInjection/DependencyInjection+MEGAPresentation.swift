import MEGAPresentation

extension DependencyInjection {
    static var secondarySceneViewModel: SecondarySceneViewModel {
        singletonSecondarySceneViewModel
    }

    static var snackbarDisplayer: some SnackbarDisplaying {
        SnackbarDisplayer(viewModel: secondarySceneViewModel)
    }

    static var appLoadingManager: some AppLoadingStateManagerProtocol {
        AppLoadingStateManager(viewModel: secondarySceneViewModel)
    }

    // MARK: - Private

    private static var singletonSecondarySceneViewModel: SecondarySceneViewModel = {
        SecondarySceneViewModel()
    }()
}

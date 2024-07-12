import SwiftUI

final class SnackBarRouter: NSObject {
    static var shared = SnackBarRouter()
    var presenter: (any SnackBarPresenting)?

    func configurePresenter(_ presenter: some SnackBarPresenting) {
        self.presenter = presenter
    }
    
    func removePresenter() {
        presenter = nil
    }
    
    @MainActor
    func present(snackBar: SnackBar) {
        guard let presenter else { return }
        let viewModel = SnackBarViewModel(snackBar: snackBar)
        let viewController = UIHostingController(rootView: SnackBarView(viewModel: viewModel))
        
        presenter.presentSnackBar(viewController: viewController)
    }
    
    func dismissSnackBar(immediate: Bool = false) {
        presenter?.dismissSnackBar(immediate: immediate)
    }
}

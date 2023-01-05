import SwiftUI

final class SnackBarRouter: NSObject {
    static var shared = SnackBarRouter()
    var presenter: SnackBarPresenting?

    func configurePresenter(_ presenter: SnackBarPresenting) {
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
    
    func dismissSnackBar() {
        presenter?.dismissSnackBar()
    }
}

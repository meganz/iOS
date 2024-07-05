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
        assert(presenter != nil, "presenter must be configured before presenting")
        guard let presenter else { return }
        let viewModel = SnackBarViewModel(snackBar: snackBar)
        let viewController = UIHostingController(rootView: SnackBarView(viewModel: viewModel))
        
        presenter.presentSnackBar(viewController: viewController)
    }
    
    func dismissSnackBar(immediate: Bool = false) {
        assert(presenter != nil, "presenter must be configured to dismiss")
        presenter?.dismissSnackBar(immediate: immediate)
    }
}

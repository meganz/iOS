import SwiftUI

class VisualMediaSearchResultsViewController: UIHostingController<VisualMediaSearchResultsView> {
    private let viewModel: VisualMediaSearchResultsViewModel
    
    init(viewModel: VisualMediaSearchResultsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: VisualMediaSearchResultsView(viewModel: viewModel))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

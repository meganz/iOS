import MEGAL10n
import SwiftUI

class MediaDiscoveryContentController: UIHostingController<MediaDiscoveryContentView> {
    
    private let viewModel: MediaDiscoveryContentViewModel
    
    init(viewModel: MediaDiscoveryContentViewModel) {
        self.viewModel = viewModel
        super.init(rootView: MediaDiscoveryContentView(viewModel: viewModel))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        viewModel.editMode = editing ? .active : .inactive
    }
    
    func toggleAllSelected() {
        viewModel.toggleAllSelected()
    }
}

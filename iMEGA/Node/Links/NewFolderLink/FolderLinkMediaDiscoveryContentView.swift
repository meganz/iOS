import FolderLink
import SwiftUI

/// A wrapper view around `MediaDiscoveryContentView`, passed to the Folder Link module to render Media Discovery.
struct FolderLinkMediaDiscoveryContentView: FolderLinkMediaDiscoveryContent {
    /// Using @ObservedObject because it is owned by FolderLink module, not `FolderLinkMediaDiscoveryContentView`
    /// It is used to send updates such sortOrder, editMode, selectAll to `MediaDiscoveryContentView`
    @ObservedObject var viewModel: FolderLinkMediaDiscoveryViewModel
    
    /// Using @StateObject because it is owned by `FolderLinkMediaDiscoveryContentView`
    /// It is used to send back selected photos to FolderLink module
    @StateObject private var contentViewModel: FolderLinkMediaDiscoveryContentViewModel
    
    private var mediaDiscoveryContentViewModel: MediaDiscoveryContentViewModel {
        contentViewModel.mediaDiscoveryContentViewModel
    }
    
    init(viewModel: FolderLinkMediaDiscoveryViewModel) {
        self.viewModel = viewModel
        _contentViewModel = StateObject(
            wrappedValue: FolderLinkMediaDiscoveryContentViewModel(
                nodeHandle: viewModel.nodeHandle,
                sortOrder: SortOrderType(megaSortOrderType: viewModel.sortOrder.toMEGASortOrderType())
            )
        )
    }
    
    var body: some View {
        MediaDiscoveryContentView(viewModel: mediaDiscoveryContentViewModel)
            .onChange(of: viewModel.sortOrder) { order in
                Task {
                    await mediaDiscoveryContentViewModel.update(sortOrder: SortOrderType(megaSortOrderType: order.toMEGASortOrderType()))
                }
            }
            .onChange(of: viewModel.editMode) { mode in
                contentViewModel.editMode = mode
            }
            .onChange(of: contentViewModel.selectedPhotos) { photos in
                viewModel.updateSelectedPhotos(photos)
            }
            .onReceive(viewModel.$selectAll.dropFirst()) { _ in
                contentViewModel.toggleSelectAll()
            }
    }
}

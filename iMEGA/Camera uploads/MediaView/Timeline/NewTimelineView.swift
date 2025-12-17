import ContentLibraries
import MEGASwiftUI
import SwiftUI

struct NewTimelineView: View {
    @ObservedObject var viewModel: NewTimelineViewModel
    
    var body: some View {
        PhotoLibraryContentView(
            viewModel: viewModel.photoLibraryContentViewModel,
            router: viewModel.photoLibraryContentViewRouter,
            onFilterUpdate: nil)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            await viewModel.loadPhotos()
        }
        .task {
            await viewModel.monitorUpdates()
        }
        .if(viewModel.showEmptyStateView) {
            $0.overlay(emptyView)
        }
    }
    
    @ViewBuilder
    private var emptyView: some View {
        let emptyScreenType = viewModel.emptyScreenTypeToShow(
            filterType: viewModel.photoLibraryContentViewModel.appliedMediaTypeFilterOption,
            filterLocation: viewModel.photoLibraryContentViewModel.appliedLocationFilterOption)
        
        if emptyScreenType == .enableCameraUploads {
            EnableCameraUploadsEmptyView(action: viewModel.navigateToCameraUploadSettings)
        } else {
            PhotoTimelineEmptyView(
                centerImage: emptyScreenType.centerImage,
                title: emptyScreenType.title,
                enableCameraUploadsAction: viewModel.enableCameraUploadsBannerAction(
                    filterLocation: viewModel.photoLibraryContentViewModel.appliedLocationFilterOption))
        }
    }
}

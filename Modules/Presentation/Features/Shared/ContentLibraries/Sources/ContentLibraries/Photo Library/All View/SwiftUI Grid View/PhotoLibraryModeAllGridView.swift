import MEGADomain
import MEGASwiftUI
import SwiftUI

struct PhotoLibraryModeAllGridView: View {
    @StateObject var viewModel: PhotoLibraryModeAllGridViewModel
    let router: any PhotoLibraryContentViewRouting
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geoProxy in
                ScrollViewReader { scrollProxy in
                    PhotoLibraryModeView(viewModel: viewModel) {
                        EnableCameraUploadsBannerButtonView { router.openCameraUploadSettings(viewModel: viewModel) }
                            .determineViewSize { @Sendable size in
                                MainActor.assumeIsolated {
                                    viewModel.photoZoomControlPositionTracker.update(viewSpace: size.height + 8)
                                }
                            }
                            .opacity(viewModel.showEnableCameraUpload ? 1 : 0)
                            .frame(maxHeight: viewModel.showEnableCameraUpload ? .infinity : 0)
                            .animation(.default, value: viewModel.showEnableCameraUpload)
                        
                        LazyVGrid(columns: viewModel.columns, spacing: 4, pinnedViews: .sectionHeaders) {
                            ForEach(viewModel.photoCategoryList) { section in
                                sectionView(for: section, viewPortSize: geoProxy.size)
                            }
                        }
                    }
                    .zoom($viewModel.zoomState)
                    .background(PhotoAutoScrollView(viewModel:
                                                        PhotoAutoScrollViewModel(viewModel: viewModel),
                                                    scrollProxy: scrollProxy))
                    .onPreferenceChange(OffsetPreferenceKey.self) { offset in
                        Task { @MainActor in
                            viewModel.photoZoomControlPositionTracker.trackContentOffset(offset)
                        }
                    }
                }
            }
            
            PhotoLibraryZoomControl(zoomState: $viewModel.zoomState)
                .offset(by: viewModel.photoZoomControlPositionTracker)
        }
        .onReceive(viewModel.$selectedNode) { photo in
            guard let photo = photo else { return }
            router.openPhotoBrowser(for: photo, allPhotos: viewModel.libraryViewModel.library.allPhotos)
        }
    }
    
    // MARK: - Private
    private func sectionView(for section: PhotoDateSection, viewPortSize: CGSize) -> some View {
        Section(header: PhotoSectionHeader(section: section).id(section.id)) {
            ForEach(section.contentList) { photo in
                router.card(for: photo, viewModel: viewModel)
                    .equatable()
                    .clipped()
                    .id(photo.position)
                    .background(Color(white: 0, opacity: 0.1))
                    .frame(in: .named(PhotoLibraryConstants.scrollViewCoordinateSpaceName))
                    .onPreferenceChange(FramePreferenceKey.self) { [position = photo.position] frame in
                        Task { @MainActor in
                            viewModel.scrollTracker.trackFrame(frame, for: position, inViewPort: viewPortSize)
                        }
                    }
                    .onAppear {
                        viewModel.scrollTracker.trackAppearedPosition(photo.position)
                    }
                    .onDisappear {
                        viewModel.scrollTracker.trackDisappearedPosition(photo.position)
                    }
                    .onTapGesture(count: 1) {
                        withAnimation {
                            viewModel.selectedNode = photo
                        }
                    }
            }
        }
    }
}

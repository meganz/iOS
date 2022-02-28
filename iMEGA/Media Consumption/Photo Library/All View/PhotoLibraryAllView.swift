import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryAllView: View {
    @StateObject var viewModel: PhotoLibraryAllViewModel
    let router: PhotoLibraryContentViewRouting
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geoProxy in
                ScrollViewReader { scrollProxy in
                    PhotoLibraryModeView(viewModel: viewModel) {
                        LazyVGrid(columns: viewModel.columns, spacing: 4, pinnedViews: .sectionHeaders) {
                            ForEach(viewModel.photoCategoryList) { section in
                                sectionView(for: section, viewPortSize: geoProxy.size)
                                    .id(section.categoryDate)
                            }
                        }
                    }
                    .zoom($viewModel.zoomState)
                    .background(PhotoAutoScrollView(viewModel:
                                                        PhotoAutoScrollViewModel(viewModel: viewModel),
                                                    scrollProxy: scrollProxy))
                }
            }
            
            PhotoLibraryZoomControl(zoomState: $viewModel.zoomState)
        }
        .fullScreenCover(item: $viewModel.selectedNode) {
            router.photoBrowser(for: $0, viewModel: viewModel)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Private
    private func sectionView(for section: PhotoDateSection, viewPortSize: CGSize) -> some View {
        Section(header: PhotoSectionHeader(section: section)) {
            ForEach(section.allPhotos) { photo in
                router.card(for: photo, viewModel: viewModel)
                    .equatable()
                    .clipped()
                    .id(photo.position)
                    .background(Color(white: 0, opacity: 0.1))
                    .frame(in: .named(PhotoLibraryConstants.scrollViewCoordinateSpaceName))
                    .onPreferenceChange(FramePreferenceKey.self) {
                        viewModel.scrollTracker.trackFrame($0, for: photo, inViewPort: viewPortSize)
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

@available(iOS 14.0, *)
extension PhotoLibraryAllView: Equatable {
    static func == (lhs: PhotoLibraryAllView, rhs: PhotoLibraryAllView) -> Bool {
        true // we are taking over the update of the view
    }
}

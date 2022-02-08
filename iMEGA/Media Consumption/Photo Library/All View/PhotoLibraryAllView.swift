import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryAllView: View {
    @StateObject var viewModel: PhotoLibraryAllViewModel
    
    let router: PhotoLibraryContentViewRouting
    
    @State private var selectedNode: NodeEntity?
    @State private var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 4),
        count: PhotoLibraryConstants.defaultColumnsNumber
    )
    
    var body: some View {
        GeometryReader { geoProxy in
            ZStack(alignment: .topTrailing) {
                ScrollViewReader { scrollProxy in
                    PhotoLibraryModeView(viewModel: viewModel) {
                        LazyVGrid(columns: columns, spacing: 4, pinnedViews: .sectionHeaders) {
                            ForEach(viewModel.photoCategoryList) { section in
                                sectionView(for: section, viewPortSize: geoProxy.size)
                                    .id(section.categoryDate)
                            }
                        }
                    }
                    .zoom(default: $viewModel.zoomLevel.onChange(zoomLevelChange), enable: false)
                    .background(PhotoAutoScrollView(viewModel:
                                                        PhotoAutoScrollViewModel(viewModel: viewModel),
                                                    scrollProxy: scrollProxy))
                    .fullScreenCover(item: $selectedNode) {
                        router.photoBrowser(for: $0, viewModel: viewModel)
                            .ignoresSafeArea()
                    }
                }
                
                ZoomButton(zoomLevel: $viewModel.zoomLevel.onChange(zoomLevelChange))
                    .opacity(viewModel.libraryViewModel.selection.editMode == .active ? 0 : 1)
            }
        }
    }
    
    // MARK: - Private
    
    private func sectionView(for section: PhotoMonthSection, viewPortSize: CGSize) -> some View {
        Section(header: PhotoMonthSectionHeader(section: section)) {
            ForEach(section.photoByMonth.allPhotos) { photo in
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
                            selectedNode = photo
                        }
                    }
            }
        }
    }
    
    private func zoomLevelChange(newLevel level: ZoomLevel) {
        columns = Array(
            repeating: .init(.flexible(), spacing: 4),
            count: level.value)
        
        viewModel.zoom(to: level.value)
    }
}

@available(iOS 14.0, *)
extension PhotoLibraryAllView: Equatable {
    static func == (lhs: PhotoLibraryAllView, rhs: PhotoLibraryAllView) -> Bool {
        true // we are taking over the update of the view
    }
}

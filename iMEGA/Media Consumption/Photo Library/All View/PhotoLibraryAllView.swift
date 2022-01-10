import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryAllView: View {
    @StateObject var viewModel: PhotoLibraryAllViewModel
    let router: PhotoLibraryContentViewRouting
    
    @State private var selectedNode: NodeEntity?
    @State private var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 1),
        count: 3
    )
    
    var body: some View {
        GeometryReader { geoProxy in
            ScrollViewReader { scrollProxy in
                PhotoLibraryModeView(viewModel: viewModel) {
                    LazyVGrid(columns: columns, spacing: 1, pinnedViews: .sectionHeaders) {
                        ForEach(viewModel.photoCategoryList) { section in
                            sectionView(for: section, viewPortSize: geoProxy.size)
                                .id(section.categoryDate)
                        }
                    }
                }
                .background(PhotoAutoScrollView(viewModel:
                                                    PhotoAutoScrollViewModel(viewModel: viewModel),
                                                scrollProxy: scrollProxy))
                .fullScreenCover(item: $selectedNode) {
                    router.photoBrowser(for: $0, viewModel: viewModel)
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    private func sectionView(for section: PhotoMonthSection, viewPortSize: CGSize) -> some View {
        Section(header: PhotoMonthSectionHeader(section: section)) {
            ForEach(section.photoByMonth.allPhotos) { photo in
                Button(action: {
                    withAnimation {
                        selectedNode = photo
                    }
                }, label: {
                    router.card(for: photo, viewModel: viewModel)
                        .equatable()
                        .clipped()
                })
                    .id(photo.position)
                    .buttonStyle(.plain)
                    .background(Color(white: 0, opacity: 0.1))
                    .frame(in: .named("scrollView"))
                    .onPreferenceChange(FramePreferenceKey.self) {
                        viewModel.scrollTracker.trackFrame($0, for: photo, inViewPort: viewPortSize)
                    }
                    .onAppear {
                        viewModel.scrollTracker.trackAppearedPosition(photo.position)
                    }
                    .onDisappear {
                        viewModel.scrollTracker.trackDisappearedPosition(photo.position)
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

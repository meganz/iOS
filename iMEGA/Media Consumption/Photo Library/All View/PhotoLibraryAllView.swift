import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryAllView: View {
    @ObservedObject var viewModel: PhotoLibraryAllViewModel
    var router: PhotoLibraryContentViewRouting
    var calculator: ScrollPositionCalculator
    
    @State private var selectedNode: NodeEntity?
    
    @State private var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 1),
        count: 3
    )
    
    var body: some View {
        GeometryReader { geoProxy in
            PhotoLibraryModeView(viewModel: viewModel) {
                LazyVGrid(columns: columns, spacing: 1, pinnedViews: .sectionHeaders) {
                    ForEach(viewModel.photoCategoryList) { section in
                        sectionView(for: section, viewPortSize: geoProxy.size)
                    }
                }
            }
        }
    }
    
    private func sectionView(for section: PhotosMonthSection, viewPortSize: CGSize) -> some View {
        Section(header: headerView(for: section)) {
            ForEach(section.photosByMonth.allPhotos) { photo in
                Button(action: {
                    if !viewModel.libraryViewModel.editingMode {
                        withAnimation {
                            selectedNode = photo
                        }
                    }
                }, label: {
                    router.card(for: photo, editingMode: viewModel.libraryViewModel.editingMode)
                        .clipped()
                })
                    .id(photo.position)
                    .buttonStyle(.plain)
                    .frame(in: .named("scrollView"))
                    .onPreferenceChange(FramePreferenceKey.self) {
                        let position = calculator.calculateScrollPosition(with: photo, frame: $0, viewPortSize: viewPortSize)
                        viewModel.libraryViewModel.currentPosition = position
                    }
            }
            .fullScreenCover(item: $selectedNode) {
                router.photoBrowser(for: $0, viewModel: viewModel)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func headerView(for section: PhotosMonthSection) -> some View {
        HStack {
            headerTitle(for: section)
                .padding(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                .blurryBackground(radius: 20)
                .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func headerTitle(for section: PhotosMonthSection) -> some View {
        if #available(iOS 15.0, *) {
            Text(section.attributedTitle)
        } else {
            Text(section.title)
                .font(.subheadline.weight(.semibold))
        }
    }
}

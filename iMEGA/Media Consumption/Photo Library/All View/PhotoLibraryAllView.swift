import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryAllView: View {
    @ObservedObject var viewModel: PhotoLibraryAllViewModel
    var router: PhotoLibraryContentViewRouting
    
    @State private var selectedNode: NodeEntity?
    
    @State private var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 1),
        count: 3
    )
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: columns, spacing: 1, pinnedViews: .sectionHeaders) {
                    ForEach(viewModel.monthSections) { section in
                        sectionView(for: section)
                    }
                }
            }
            .onAppear {
                proxy.scrollTo(viewModel.currentScrollPositionId)
            }
        }
    }
    
    private func sectionView(for section: PhotoMonthSection) -> some View {
        Section(header: headerView(for: section)) {
            ForEach(section.photosByMonth.allPhotos) { photo in
                Button(action: {
                    withAnimation {
                        selectedNode = photo
                    }
                }, label: {
                    router.card(for: photo)
                        .clipped()
                })
                    .id(viewModel.positionId(for: photo))
                    .buttonStyle(.plain)
            }
            .fullScreenCover(item: $selectedNode) {
                router.photoBrowser(for: $0, viewModel: viewModel)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func headerView(for section: PhotoMonthSection) -> some View {
        HStack {
            headerTitle(for: section)
                .padding(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                .blurryBackground(radius: 20)
                .padding(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func headerTitle(for section: PhotoMonthSection) -> some View {
        if #available(iOS 15.0, *) {
            Text(section.attributedTitle)
        } else {
            Text(section.title)
                .font(.subheadline.weight(.semibold))
        }
    }
}

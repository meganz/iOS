import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryAllView: View {
    @ObservedObject var viewModel: PhotoLibraryAllViewModel
    @State private var selectedNode: NodeEntity?
    
    @State private var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 1),
        count: 3
    )
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 1, pinnedViews: .sectionHeaders) {
            ForEach(viewModel.monthSections) { section in
                Section(header: headerView(for: section)) {
                    ForEach(section.photosByMonth.allPhotos) { photo in
                        Button(action: {
                            self.selectedNode = photo
                        }) {
                            cell(for: photo)
                        }
                    }
                    .fullScreenCover(item: $selectedNode) {
                        let node = $0.toMEGANode(in: MEGASdkManager.sharedMEGASdk())
                        
                        PhotoBrowser(node: node, megaNodes: viewModel.library.underlyingMEGANodes)
                            .ignoresSafeArea()
                    }
                }
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
    
    private func cell(for photo: NodeEntity) -> some View {
        let thumbnailRepo = ThumbnailRepository(
            sdk: MEGASdkManager.sharedMEGASdk(),
            fileRepo: FileSystemRepository(fileManager: FileManager.default)
        )
        
        let photoCellViewModel = PhotoCellViewModel(photo: photo, thumbnailUseCase: ThumbnailUseCase(repository: thumbnailRepo))
        
        return PhotoCell(viewModel: photoCellViewModel)
            .clipped()
    }
}

import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryAllView: View {
    @ObservedObject var viewModel: PhotoLibraryAllViewModel
    
    @State private var columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 1),
        count: 3
    )
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 1, pinnedViews: .sectionHeaders) {
            ForEach(viewModel.monthSections) { section in
                Section(header: headerView(for: section)) {
                    ForEach(section.photosByMonth.allPhotos) { photo in
                        cell(for: photo)
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

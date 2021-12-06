import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryYearView: View {
    private enum Constants {
        static let cardMinimumWidth: CGFloat = 300
        static let cardMaximumWidth: CGFloat = 1000
        static let cardHeight: CGFloat = 250
    }
    
    @ObservedObject var viewModel: PhotoLibraryYearViewModel
    
    private let columns = [
        GridItem(
            .adaptive(minimum: Constants.cardMinimumWidth,
                      maximum: Constants.cardMaximumWidth)
        )
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.photosByYearList) { photosByYear in
                card(for: photosByYear)
            }
        }.padding()
    }
    
    private func card(for year: PhotosByYear) -> some View {
        let thumbnailRepo = ThumbnailRepository(
            sdk: MEGASdkManager.sharedMEGASdk(),
            fileRepo: FileSystemRepository(fileManager: FileManager.default)
        )
        let yearCardViewModel = PhotoYearCardViewModel(
            photosByYear: year,
            thumbnailUseCase: ThumbnailUseCase(repository: thumbnailRepo)
        )
        
        return PhotoYearCard(viewModel: yearCardViewModel)
            .frame(height: Constants.cardHeight)
    }
}

import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryMonthView: View {
    private enum Constants {
        static let cardMinimumWidth: CGFloat = 300
        static let cardMaximumWidth: CGFloat = 1000
        static let cardHeight: CGFloat = 250
    }
    
    @ObservedObject var viewModel: PhotoLibraryMonthViewModel
    
    private let columns = [
        GridItem(
            .adaptive(minimum: Constants.cardMinimumWidth,
                      maximum: Constants.cardMaximumWidth)
        )
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.photosByMonthList) { photosByMonth in
                card(for: photosByMonth)
            }
        }.padding()
    }
    
    private func card(for month: PhotosByMonth) -> some View {
        let thumbnailRepo = ThumbnailRepository(
            sdk: MEGASdkManager.sharedMEGASdk(),
            fileRepo: FileSystemRepository(fileManager: FileManager.default)
        )
        
        let monthCardViewModel = PhotoMonthCardViewModel(
            photosByMonth: month,
            thumbnailUseCase: ThumbnailUseCase(repository: thumbnailRepo)
        )
        
        return PhotoMonthCard(viewModel: monthCardViewModel)
            .frame(height: Constants.cardHeight)
    }
}

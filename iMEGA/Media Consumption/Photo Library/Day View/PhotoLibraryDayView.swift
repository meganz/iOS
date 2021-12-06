import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryDayView: View {
    private enum Constants {
        static let cardMinimumWidth: CGFloat = 300
        static let cardMaximumWidth: CGFloat = 1000
        static let cardHeight: CGFloat = 250
    }
    
    @ObservedObject var viewModel: PhotoLibraryDayViewModel
    
    private let columns = [
        GridItem(
            .adaptive(minimum: Constants.cardMinimumWidth,
                      maximum: Constants.cardMaximumWidth)
        )
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.photosByDayList) { photosByDay in
                card(for: photosByDay)
            }
        }.padding()
    }
    
    private func card(for Day: PhotosByDay) -> some View {
        let thumbnailRepo = ThumbnailRepository(
            sdk: MEGASdkManager.sharedMEGASdk(),
            fileRepo: FileSystemRepository(fileManager: FileManager.default)
        )
        
        let dayCardViewModel = PhotoDayCardViewModel(
            photosByDay: Day,
            thumbnailUseCase: ThumbnailUseCase(repository: thumbnailRepo)
        )
        
        return PhotoDayCard(viewModel: dayCardViewModel)
            .frame(height: Constants.cardHeight)
    }
}

import Foundation
import SwiftUI

@available(iOS 14.0, *)
protocol PhotoLibraryContentViewRouting {
    func card(for photosByYear: PhotosByYear) -> PhotoYearCard
    func card(for photosByMonth: PhotosByMonth) -> PhotoMonthCard
    func card(for photosByDay: PhotosByDay) -> PhotoDayCard
    func card(for photo: NodeEntity, editingMode: Bool) -> PhotoCell
    func photoBrowser(for photo: NodeEntity, viewModel: PhotoLibraryAllViewModel) -> PhotoBrowser
}

@available(iOS 14.0, *)
final class PhotoLibraryContentViewRouter: PhotoLibraryContentViewRouting {
    func card(for photosByYear: PhotosByYear) -> PhotoYearCard {
        let thumbnailRepo = ThumbnailRepository(
            sdk: MEGASdkManager.sharedMEGASdk(),
            fileRepo: FileSystemRepository(fileManager: FileManager.default)
        )
        let yearCardViewModel = PhotoYearCardViewModel(
            photosByYear: photosByYear,
            thumbnailUseCase: ThumbnailUseCase(repository: thumbnailRepo)
        )
        
        return PhotoYearCard(viewModel: yearCardViewModel)
    }
    
    func card(for photosByMonth: PhotosByMonth) -> PhotoMonthCard {
        let thumbnailRepo = ThumbnailRepository(
            sdk: MEGASdkManager.sharedMEGASdk(),
            fileRepo: FileSystemRepository(fileManager: FileManager.default)
        )
        
        let monthCardViewModel = PhotoMonthCardViewModel(
            photosByMonth: photosByMonth,
            thumbnailUseCase: ThumbnailUseCase(repository: thumbnailRepo)
        )
        
        return PhotoMonthCard(viewModel: monthCardViewModel)
    }
    
    func card(for photosByDay: PhotosByDay) -> PhotoDayCard {
        let thumbnailRepo = ThumbnailRepository(
            sdk: MEGASdkManager.sharedMEGASdk(),
            fileRepo: FileSystemRepository(fileManager: FileManager.default)
        )
        
        let dayCardViewModel = PhotoDayCardViewModel(
            photosByDay: photosByDay,
            thumbnailUseCase: ThumbnailUseCase(repository: thumbnailRepo)
        )
        
        return PhotoDayCard(viewModel: dayCardViewModel)
    }
    
    func card(for photo: NodeEntity, editingMode: Bool) -> PhotoCell {
        let thumbnailRepo = ThumbnailRepository(
            sdk: MEGASdkManager.sharedMEGASdk(),
            fileRepo: FileSystemRepository(fileManager: FileManager.default)
        )
        
        let photoCellViewModel = PhotoCellViewModel(photo: photo,
                                                    thumbnailUseCase: ThumbnailUseCase(repository: thumbnailRepo))
        
        return PhotoCell(inEditingMode: editingMode, viewModel: photoCellViewModel)
    }
    
    func photoBrowser(for photo: NodeEntity, viewModel: PhotoLibraryAllViewModel) -> PhotoBrowser {
        let node = photo.toMEGANode(in: MEGASdkManager.sharedMEGASdk())
        return PhotoBrowser(node: node, megaNodes: viewModel.libraryViewModel.library.underlyingMEGANodes)
    }
}

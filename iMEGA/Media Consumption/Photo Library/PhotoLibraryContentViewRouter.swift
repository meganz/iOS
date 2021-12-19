import Foundation
import SwiftUI

@available(iOS 14.0, *)
protocol PhotoLibraryContentViewRouting {
    func card(for photosByYear: PhotosByYear) -> PhotoYearCard
    func card(for photosByMonth: PhotosByMonth) -> PhotoMonthCard
    func card(for photosByDay: PhotosByDay) -> PhotoDayCard
    func card(for photo: NodeEntity, isEditingMode: Bool) -> PhotoCell
    func photoBrowser(for photo: NodeEntity, viewModel: PhotoLibraryAllViewModel) -> PhotoBrowser
}

@available(iOS 14.0, *)
final class PhotoLibraryContentViewRouter: PhotoLibraryContentViewRouting {
    func card(for photosByYear: PhotosByYear) -> PhotoYearCard {
        let yearCardViewModel = PhotoYearCardViewModel(
            photosByYear: photosByYear,
            thumbnailUseCase: ThumbnailUseCase.default
        )
        
        return PhotoYearCard(viewModel: yearCardViewModel)
    }
    
    func card(for photosByMonth: PhotosByMonth) -> PhotoMonthCard {
        let monthCardViewModel = PhotoMonthCardViewModel(
            photosByMonth: photosByMonth,
            thumbnailUseCase: ThumbnailUseCase.default
        )
        
        return PhotoMonthCard(viewModel: monthCardViewModel)
    }
    
    func card(for photosByDay: PhotosByDay) -> PhotoDayCard {
        let dayCardViewModel = PhotoDayCardViewModel(
            photosByDay: photosByDay,
            thumbnailUseCase: ThumbnailUseCase.default
        )
        return PhotoDayCard(viewModel: dayCardViewModel)
    }
    
    func card(for photo: NodeEntity, isEditingMode: Bool) -> PhotoCell {
        let photoCellViewModel = PhotoCellViewModel(
            photo: photo,
            thumbnailUseCase: ThumbnailUseCase.default,
            isEditingMode: isEditingMode
        )
        return PhotoCell(viewModel: photoCellViewModel)
    }
    
    func photoBrowser(for photo: NodeEntity, viewModel: PhotoLibraryAllViewModel) -> PhotoBrowser {
        let node = photo.toMEGANode(in: MEGASdkManager.sharedMEGASdk())
        return PhotoBrowser(node: node, megaNodes: viewModel.libraryViewModel.library.underlyingMEGANodes)
    }
}

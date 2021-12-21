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
        return PhotoYearCard(
            viewModel: PhotoYearCardViewModel(
                photosByYear: photosByYear,
                thumbnailUseCase: ThumbnailUseCase.default
            )
        )
    }
    
    func card(for photosByMonth: PhotosByMonth) -> PhotoMonthCard {
        return PhotoMonthCard(
            viewModel: PhotoMonthCardViewModel(
                photosByMonth: photosByMonth,
                thumbnailUseCase: ThumbnailUseCase.default
            )
        )
    }
    
    func card(for photosByDay: PhotosByDay) -> PhotoDayCard {
        return PhotoDayCard(
            viewModel: PhotoDayCardViewModel(
                photosByDay: photosByDay,
                thumbnailUseCase: ThumbnailUseCase.default
            )
        )
    }
    
    func card(for photo: NodeEntity, isEditingMode: Bool) -> PhotoCell {
        return PhotoCell(
            viewModel: PhotoCellViewModel(
                photo: photo,
                thumbnailUseCase: ThumbnailUseCase.default,
                isEditingMode: isEditingMode
            )
        )
    }
    
    func photoBrowser(for photo: NodeEntity, viewModel: PhotoLibraryAllViewModel) -> PhotoBrowser {
        let node = photo.toMEGANode(in: MEGASdkManager.sharedMEGASdk())
        return PhotoBrowser(node: node, megaNodes: viewModel.libraryViewModel.library.underlyingMEGANodes)
    }
}

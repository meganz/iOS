import Foundation
import SwiftUI
import Combine

@available(iOS 14.0, *)
protocol PhotoLibraryContentViewRouting {
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard
    func card(for photo: NodeEntity, viewModel: PhotoLibraryAllViewModel) -> PhotoCell
    func photoBrowser(for photo: NodeEntity, viewModel: PhotoLibraryAllViewModel) -> PhotoBrowser
}

@available(iOS 14.0, *)
struct PhotoLibraryContentViewRouter: PhotoLibraryContentViewRouting {
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard {
        return PhotoYearCard(
            viewModel: PhotoYearCardViewModel(
                photoByYear: photoByYear,
                thumbnailUseCase: ThumbnailUseCase.default
            )
        )
    }
    
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard {
        return PhotoMonthCard(
            viewModel: PhotoMonthCardViewModel(
                photoByMonth: photoByMonth,
                thumbnailUseCase: ThumbnailUseCase.default
            )
        )
    }
    
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard {
        return PhotoDayCard(
            viewModel: PhotoDayCardViewModel(
                photoByDay: photoByDay,
                thumbnailUseCase: ThumbnailUseCase.default
            )
        )
    }
    
    func card(for photo: NodeEntity, viewModel: PhotoLibraryAllViewModel) -> PhotoCell {
        return PhotoCell(
            viewModel: PhotoCellViewModel(
                photo: photo,
                viewModel: viewModel,
                thumbnailUseCase: ThumbnailUseCase.default
            )
        )
    }
    
    func photoBrowser(for photo: NodeEntity, viewModel: PhotoLibraryAllViewModel) -> PhotoBrowser {
        let node = photo.toMEGANode(in: MEGASdkManager.sharedMEGASdk())
        return PhotoBrowser(node: node, megaNodes: viewModel.libraryViewModel.library.underlyingMEGANodes)
    }
}

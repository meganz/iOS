import Foundation
import SwiftUI
import Combine
import MEGADomain

protocol PhotoLibraryContentViewRouting {
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard
    func card(for photo: NodeEntity, viewModel: PhotoLibraryModeAllGridViewModel) -> PhotoCell
    func openPhotoBrowser(for photo: NodeEntity, allPhotos: [NodeEntity])
}

struct PhotoLibraryContentViewRouter: PhotoLibraryContentViewRouting {
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard {
        return PhotoYearCard(
            viewModel: PhotoYearCardViewModel(
                photoByYear: photoByYear,
                thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
            )
        )
    }
    
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard {
        return PhotoMonthCard(
            viewModel: PhotoMonthCardViewModel(
                photoByMonth: photoByMonth,
                thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
            )
        )
    }
    
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard {
        return PhotoDayCard(
            viewModel: PhotoDayCardViewModel(
                photoByDay: photoByDay,
                thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo)
            )
        )
    }
    
    func card(for photo: NodeEntity, viewModel: PhotoLibraryModeAllGridViewModel) -> PhotoCell {
        return PhotoCell(
            viewModel: PhotoCellViewModel(
                photo: photo,
                viewModel: viewModel,
                thumbnailUseCase: ThumbnailUseCase(repository: ThumbnailRepository.newRepo),
                mediaUseCase: MediaUseCase(fileSearchRepo: FilesSearchRepository.newRepo)
            )
        )
    }
    
    func openPhotoBrowser(for photo: NodeEntity, allPhotos: [NodeEntity]) {
        guard var topController = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        if topController.definesPresentationContext == false && topController.children.isEmpty { return }
        
        let photoBrowser = MEGAPhotoBrowserViewController.photoBrowser(currentPhoto: photo, allPhotos: allPhotos)
        
        topController.modalPresentationStyle = .popover
        topController.present(photoBrowser, animated: true)
    }
}

import Combine
import Foundation
import MEGADomain
import SwiftUI

protocol PhotoLibraryContentViewRouting {
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard
    func card(for photo: NodeEntity, viewModel: PhotoLibraryModeAllGridViewModel) -> PhotoCell
    func openPhotoBrowser(for photo: NodeEntity, allPhotos: [NodeEntity])
}

struct PhotoLibraryContentViewRouter: PhotoLibraryContentViewRouting {
    private let contentMode: PhotoLibraryContentMode
    
    init(contentMode: PhotoLibraryContentMode = .library) {
        self.contentMode = contentMode
    }
    
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard {
        return PhotoYearCard(
            viewModel: PhotoYearCardViewModel(
                photoByYear: photoByYear,
                thumbnailUseCase: makeThumnailUseCase()
            )
        )
    }
    
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard {
        return PhotoMonthCard(
            viewModel: PhotoMonthCardViewModel(
                photoByMonth: photoByMonth,
                thumbnailUseCase: makeThumnailUseCase()
            )
        )
    }
    
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard {
        return PhotoDayCard(
            viewModel: PhotoDayCardViewModel(
                photoByDay: photoByDay,
                thumbnailUseCase: makeThumnailUseCase()
            )
        )
    }
    
    func card(for photo: NodeEntity, viewModel: PhotoLibraryModeAllGridViewModel) -> PhotoCell {
        return PhotoCell(
            viewModel: PhotoCellViewModel(
                photo: photo,
                viewModel: viewModel,
                thumbnailUseCase: makeThumnailUseCase()
            )
        )
    }
    
    func openPhotoBrowser(for photo: NodeEntity, allPhotos: [NodeEntity]) {
        guard var topController = UIApplication.shared.keyWindow?.rootViewController else { return }
        
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        if topController.definesPresentationContext == false && topController.children.isEmpty { return }
        let isFolderLink = contentMode == .mediaDiscoveryFolderLink
        let displayMode: DisplayMode = isFolderLink ? .nodeInsideFolderLink : .cloudDrive
        let photoBrowser = MEGAPhotoBrowserViewController.photoBrowser(currentPhoto: photo, allPhotos: allPhotos,
                                                                       displayMode: displayMode)
        
        topController.modalPresentationStyle = .popover
        topController.present(photoBrowser, animated: true)
    }
    
    private func makeThumnailUseCase() -> some ThumbnailUseCaseProtocol {
        return ThumbnailUseCase.makeThumbnailUseCase(mode: contentMode)
    }
}

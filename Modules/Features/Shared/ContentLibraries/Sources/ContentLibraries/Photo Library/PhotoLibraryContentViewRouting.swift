import Foundation
import MEGADomain
import SwiftUI

@MainActor
public protocol PhotoLibraryContentViewRouting {
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard
    func openPhotoBrowser(for photo: NodeEntity, allPhotos: [NodeEntity])
    func openCameraUploadSettings(viewModel: PhotoLibraryModeAllViewModel)
    func showTakenDownNodeAlert()
}

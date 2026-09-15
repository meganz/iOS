import Foundation
import MEGADomain
import SwiftUI

@MainActor
public protocol PhotoLibraryContentViewRouting {
    func card(for photoByYear: PhotoByYear) -> PhotoYearCard
    func card(for photoByMonth: PhotoByMonth) -> PhotoMonthCard
    func card(for photoByDay: PhotoByDay) -> PhotoDayCard
    func openPhotoBrowser(for photo: NodeEntity, allPhotos: [NodeEntity])

    /// Opens the browser on a paginated library: the handover carries only the contiguous run
    /// around the tapped photo, and the browser pages outward from there on its own.
    func openPhotoBrowser(for photo: NodeEntity, in context: PhotoBrowserPaginationContext)
    func openCameraUploadSettings(viewModel: PhotoLibraryModeAllViewModel)
    func showTakenDownNodeAlert()
}

public extension PhotoLibraryContentViewRouting {
    /// Falls back to the whole-sequence path with the run as the loaded array, so a router that
    /// cannot paginate still opens on something sensible instead of having to say so.
    func openPhotoBrowser(for photo: NodeEntity, in context: PhotoBrowserPaginationContext) {
        openPhotoBrowser(for: photo, allPhotos: context.nodes)
    }
}

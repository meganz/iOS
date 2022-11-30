import SwiftUI

struct PhotoLibraryDayView: View {
    @StateObject var viewModel: PhotoLibraryDayViewModel
    let router: PhotoLibraryContentViewRouting

    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            router.card(for: $0)
        }
    }
}

extension PhotoLibraryDayView: Equatable {
    static func == (lhs: PhotoLibraryDayView, rhs: PhotoLibraryDayView) -> Bool {
        true // we are taking over the update of the view
    }
}

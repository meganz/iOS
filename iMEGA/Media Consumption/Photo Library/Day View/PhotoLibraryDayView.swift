import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryDayView: View {
    @StateObject var viewModel: PhotoLibraryDayViewModel
    var router: PhotoLibraryContentViewRouting

    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            router.card(for: $0)
        }
    }
}

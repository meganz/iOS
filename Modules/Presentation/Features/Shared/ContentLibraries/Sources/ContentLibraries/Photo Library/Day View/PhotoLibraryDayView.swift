import SwiftUI

struct PhotoLibraryDayView: View {
    @StateObject var viewModel: PhotoLibraryDayViewModel
    let router: any PhotoLibraryContentViewRouting

    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            router.card(for: $0)
        }
    }
}

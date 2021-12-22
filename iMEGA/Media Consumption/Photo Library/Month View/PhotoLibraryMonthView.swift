import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryMonthView: View {
    @StateObject var viewModel: PhotoLibraryMonthViewModel
    var router: PhotoLibraryContentViewRouting
    
    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            router.card(for: $0)
        }
    }
}

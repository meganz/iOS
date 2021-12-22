import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryYearView: View {
    @StateObject var viewModel: PhotoLibraryYearViewModel
    var router: PhotoLibraryContentViewRouting
    
    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            router.card(for: $0)
        }
    }
}

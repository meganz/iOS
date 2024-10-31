import SwiftUI

struct PhotoLibraryYearView: View {
    @StateObject var viewModel: PhotoLibraryYearViewModel
    let router: any PhotoLibraryContentViewRouting
    
    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            router.card(for: $0)
        }
    }
}

import SwiftUI

struct PhotoLibraryMonthView: View {
    @StateObject var viewModel: PhotoLibraryMonthViewModel
    let router: any PhotoLibraryContentViewRouting
    
    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            router.card(for: $0)
        }
    }
}

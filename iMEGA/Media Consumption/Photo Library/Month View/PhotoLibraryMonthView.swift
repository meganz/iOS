import SwiftUI

struct PhotoLibraryMonthView: View {
    @StateObject var viewModel: PhotoLibraryMonthViewModel
    let router: PhotoLibraryContentViewRouting
    
    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            router.card(for: $0)
        }
    }
}

extension PhotoLibraryMonthView: Equatable {
    static func == (lhs: PhotoLibraryMonthView, rhs: PhotoLibraryMonthView) -> Bool {
        true // we are taking over the update of the view
    }
}

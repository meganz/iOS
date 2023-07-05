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

extension PhotoLibraryYearView: Equatable {
    static func == (lhs: PhotoLibraryYearView, rhs: PhotoLibraryYearView) -> Bool {
        true // we are taking over the update of the view
    }
}

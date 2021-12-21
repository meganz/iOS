import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryYearView: View {
    @StateObject var viewModel: PhotoLibraryYearViewModel
    var router: PhotoLibraryContentViewRouting
    
    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            cell(for: $0)
        }
    }
    
    private func cell(for photosByYear: PhotosByYear) -> some View {
        Button(action: {
            withAnimation {
                viewModel.didTapYearCard(photosByYear)
            }
        }, label: {
            router.card(for: photosByYear)
                .frame(height: PhotoLibraryConstants.cardHeight)
        })
            .id(photosByYear.position)
            .buttonStyle(.plain)
    }
}

import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryMonthView: View {
    @StateObject var viewModel: PhotoLibraryMonthViewModel
    var router: PhotoLibraryContentViewRouting
    
    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            cell(for: $0)
        }
    }
    
    private func cell(for photosByMonth: PhotosByMonth) -> some View {
        Button(action: {
            withAnimation {
                viewModel.didTapMonthCard(photosByMonth)
            }
        }, label: {
            router.card(for: photosByMonth)
                .frame(height: PhotoLibraryConstants.cardHeight)
        })
            .id(photosByMonth.position)
            .buttonStyle(.plain)
    }
    
}

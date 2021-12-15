import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryDayView: View {
    @ObservedObject var viewModel: PhotoLibraryDayViewModel
    var router: PhotoLibraryContentViewRouting

    var body: some View {
        PhotoLibraryModeCardView(viewModel: viewModel) {
            cell(for: $0)
        }
    }
    
    private func cell(for photosByDay: PhotosByDay) -> some View {
        Button(action: {
            withAnimation {
                viewModel.didTapDayCard(photosByDay)
            }
        }, label: {
            router.card(for: photosByDay)
                .frame(height: PhotoLibraryConstants.cardHeight)
        })
            .id(photosByDay.position)
            .buttonStyle(.plain)
    }
}

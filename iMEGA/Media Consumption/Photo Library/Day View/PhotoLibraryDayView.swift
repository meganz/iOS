import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryDayView: View {
    @ObservedObject var viewModel: PhotoLibraryDayViewModel
    var router: PhotoLibraryContentViewRouting

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: PhotoLibraryConstants.cardColumns, spacing: 16) {
                    ForEach(viewModel.photosByDayList) { photosByDay in
                        cell(for: photosByDay)
                    }
                }
                .padding()
            }
            .onAppear {
                proxy.scrollTo(viewModel.currentScrollPositionId)
            }
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
            .id(viewModel.positionId(for: photosByDay))
            .buttonStyle(.plain)
    }
}

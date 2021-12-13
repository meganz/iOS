import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryMonthView: View {
    @ObservedObject var viewModel: PhotoLibraryMonthViewModel
    var router: PhotoLibraryContentViewRouting
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: PhotoLibraryConstants.cardColumns, spacing: 16) {
                    ForEach(viewModel.photosByMonthList) { photosByMonth in
                        cell(for: photosByMonth)
                    }
                }
                .padding()
            }
            .onAppear {
                proxy.scrollTo(viewModel.currentScrollPositionId)
            }
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
            .id(viewModel.positionId(for: photosByMonth))
            .buttonStyle(.plain)
    }
    
}

import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryYearView: View {
    @ObservedObject var viewModel: PhotoLibraryYearViewModel
    var router: PhotoLibraryContentViewRouting
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(columns: PhotoLibraryConstants.cardColumns, spacing: 16) {
                    ForEach(viewModel.photosByYearList) { photosByYear in
                        cell(for: photosByYear)
                    }
                }
                .padding()
            }
            .onAppear {
                proxy.scrollTo(viewModel.currentScrollPositionId)
            }
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
            .id(viewModel.positionId(for: photosByYear))
            .buttonStyle(.plain)
    }
}

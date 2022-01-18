import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryContentView: View {
    @ObservedObject var viewModel: PhotoLibraryContentViewModel
    var router: PhotoLibraryContentViewRouting
    
    var body: some View {
        if viewModel.library.isEmpty {
            ProgressView()
                .scaleEffect(1.5)
        } else {
            if #available(iOS 15.0, *) {
                photoContent()
                    .safeAreaInset(edge: .bottom) {
                        PhotoLibraryPicker(viewModel: viewModel)
                    }
            } else {
                ZStack(alignment: .bottom) {
                    photoContent()
                    PhotoLibraryPicker(viewModel: viewModel)
                }
            }
        }
    }
    
    @ViewBuilder
    private func photoContent() -> some View {
        ZStack {
            switch viewModel.selectedMode {
            case .year:
                PhotoLibraryYearView(
                    viewModel: PhotoLibraryYearViewModel(libraryViewModel: viewModel),
                    router: router
                )
                    .equatable()
            case .month:
                PhotoLibraryMonthView(
                    viewModel: PhotoLibraryMonthViewModel(libraryViewModel: viewModel),
                    router: router
                )
                    .equatable()
            case .day:
                PhotoLibraryDayView(
                    viewModel: PhotoLibraryDayViewModel(libraryViewModel: viewModel),
                    router: router
                )
                    .equatable()
            case .all:
                EmptyView()
            }
            
            PhotoLibraryAllView(
                viewModel: PhotoLibraryAllViewModel(libraryViewModel: viewModel),
                router: router
            )
                .equatable()
                .opacity(viewModel.selectedMode == .all ? 1 : 0)
                .zIndex(viewModel.selectedMode == .all ? 1 : -1)
        }
    }
}

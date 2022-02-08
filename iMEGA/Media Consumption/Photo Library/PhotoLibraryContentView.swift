import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryContentView: View {
    @ObservedObject var viewModel: PhotoLibraryContentViewModel
    var router: PhotoLibraryContentViewRouting
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        if viewModel.library.isEmpty {
            ProgressView()
                .scaleEffect(1.5)
        } else {
            Group {
                if #available(iOS 15.0, *) {
                    photoContent()
                        .safeAreaInset(edge: .bottom) {
                            PhotoLibraryPicker(selectedMode: $viewModel.selectedMode)
                        }
                } else {
                    ZStack(alignment: .bottom) {
                        photoContent()
                        PhotoLibraryPicker(selectedMode: $viewModel.selectedMode)
                    }
                }
            }
            .environment(\.editMode, $editMode)
            .onReceive(viewModel.selection.$editMode.dropFirst()) {
                editMode = $0
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

import MEGADesignToken
import MEGASwiftUI
import SwiftUI

public struct PhotoLibraryContentView: View {
    @ObservedObject var viewModel: PhotoLibraryContentViewModel
    var router: any PhotoLibraryContentViewRouting
    let onFilterUpdate: ((PhotosFilterOptions, PhotosFilterOptions) -> Void)?
    
    @State private var editMode: EditMode
    
    public init(viewModel: PhotoLibraryContentViewModel, router: any PhotoLibraryContentViewRouting, onFilterUpdate: ( (PhotosFilterOptions, PhotosFilterOptions) -> Void)?, editMode: EditMode = .inactive) {
        self.viewModel = viewModel
        self.router = router
        self.onFilterUpdate = onFilterUpdate
        self.editMode = editMode
    }
    
    public var body: some View {
        content()
            .background(TokenColors.Background.page.swiftUI)
            .overlay(placeholder)
            .environment(\.editMode, $editMode)
            .onReceive(viewModel.selection.$editMode) {
                editMode = $0
            }
            .sheet(isPresented: $viewModel.showFilter) {
                PhotoLibraryFilterView(viewModel: viewModel.filterViewModel,
                                       isPresented: $viewModel.showFilter,
                                       onFilterUpdate: onFilterUpdate)
            }
    }
    
    @ViewBuilder
    private func content() -> some View {
        if viewModel.shouldShowPhotoLibraryPicker {
            photoContent()
                .safeAreaInset(edge: .bottom) {
                    if editMode.isEditing && viewModel.contentMode == .library {
                        EmptyView()
                    } else {
                        PhotoLibraryPicker(selectedMode: $viewModel.selectedMode)
                    }
                }
        } else {
            photoContent()
                .safeAreaInset(edge: .bottom) {
                    EmptyView().frame(height: 64)
                }
        }
    }
    private var placeholder: some View {
        PhotoLibraryPlaceholderView(isActive: viewModel.library.isEmpty)
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
            case .month:
                PhotoLibraryMonthView(
                    viewModel: PhotoLibraryMonthViewModel(libraryViewModel: viewModel),
                    router: router
                )
            case .day:
                PhotoLibraryDayView(
                    viewModel: PhotoLibraryDayViewModel(libraryViewModel: viewModel),
                    router: router
                )
            case .all:
                EmptyView()
            }
            
            PhotoLibraryModeAllView(viewModel: viewModel, router: router)
                .opacity(viewModel.selectedMode == .all ? 1.0 : 0.0)
                .zIndex(viewModel.selectedMode == .all ? 1.0 : -1.0)
        }
    }
}

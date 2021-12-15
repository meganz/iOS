import Foundation
import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryModeCardView<Category, VM: PhotoLibraryModeViewModel<Category>, Content: View>: View where Category: PhotosChronologicalCategory {
    @ObservedObject var viewModel: VM
    private let cellBuilder: (Category) -> Content
    var calculator: ScrollPositionCalculator
    
    init(viewModel: VM, @ViewBuilder cellBuilder: @escaping (Category) -> Content) {
        self.viewModel = viewModel
        self.cellBuilder = cellBuilder
        calculator = ScrollPositionCalculator()
    }
    
    var body: some View {
        GeometryReader { geoProxy in
            PhotoLibraryModeView(viewModel: viewModel) {
                LazyVGrid(columns: PhotoLibraryConstants.cardColumns, spacing: PhotoLibraryConstants.cardRowPadding) {
                    ForEach(viewModel.photoCategoryList) { category in
                        cellBuilder(category)
                            .frame(in: .named("scrollView"))
                            .onPreferenceChange(FramePreferenceKey.self) {
                                let position = calculator.calculateScrollPosition(with: category, frame: $0, viewPortSize: geoProxy.size)
                                viewModel.libraryViewModel.currentPosition = position
                            }
                    }
                }
                .padding(PhotoLibraryConstants.libraryPadding)
            }
        }
    }
}

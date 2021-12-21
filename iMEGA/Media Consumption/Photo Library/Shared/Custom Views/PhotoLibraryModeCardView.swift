import Foundation
import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryModeCardView<Category, VM: PhotoLibraryModeCardViewModel<Category>, Content: View>: View where Category: PhotosChronologicalCategory {
    private let cellBuilder: (Category) -> Content
    
    @ObservedObject var viewModel: VM
    
    init(viewModel: VM, @ViewBuilder cellBuilder: @escaping (Category) -> Content) {
        self.viewModel = viewModel
        self.cellBuilder = cellBuilder
    }
    
    var body: some View {
        GeometryReader { geoProxy in
            PhotoLibraryModeView(viewModel: viewModel) {
                LazyVGrid(columns: PhotoLibraryConstants.cardColumns, spacing: PhotoLibraryConstants.cardRowPadding) {
                    ForEach(viewModel.photoCategoryList) { category in
                        cellBuilder(category)
                            .frame(in: .named("scrollView"))
                            .onPreferenceChange(FramePreferenceKey.self) {
                                viewModel.scrollCalculator.recordFrame($0, for: category, inViewPort: geoProxy.size)
                            }
                    }
                }
                .padding(PhotoLibraryConstants.libraryPadding)
            }
        }
    }
}

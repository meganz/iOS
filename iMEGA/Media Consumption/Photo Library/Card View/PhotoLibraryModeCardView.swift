import Foundation
import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryModeCardView<Category, VM, Content>: View where Category: PhotoChronologicalCategory, VM: PhotoLibraryModeCardViewModel<Category>, Content: View, Content: Equatable {
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
                        card(for: category, viewPortSize: geoProxy.size)
                    }
                }
                .padding(PhotoLibraryConstants.libraryPadding)
            }
        }
    }
    
    private func card(for category: Category, viewPortSize: CGSize) -> some View {
        Button(action: {
            withAnimation {
                viewModel.didTapCategory(category)
            }
        }, label: {
            cellBuilder(category)
                .equatable()
                .frame(height: PhotoLibraryConstants.cardHeight)
        })
            .id(category.position)
            .buttonStyle(.plain)
            .frame(in: .named("scrollView"))
            .onPreferenceChange(FramePreferenceKey.self) {
                viewModel.scrollTracker.trackFrame($0, for: category, inViewPort: viewPortSize)
            }
            .onAppear {
                viewModel.scrollTracker.trackAppearedPosition(category.position)
            }
            .onDisappear {
                viewModel.scrollTracker.trackDisappearedPosition(category.position)
            }
    }
}

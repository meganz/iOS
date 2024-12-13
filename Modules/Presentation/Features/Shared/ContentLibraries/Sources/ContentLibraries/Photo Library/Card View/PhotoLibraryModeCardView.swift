import Foundation
import MEGASwiftUI
import SwiftUI

struct PhotoLibraryModeCardView<Category, VM, Content>: View where Category: PhotoChronologicalCategory, VM: PhotoLibraryModeCardViewModel<Category>, Content: View {
    private let cellBuilder: (Category) -> Content
    
    @ObservedObject var viewModel: VM
    
    init(viewModel: VM, @ViewBuilder cellBuilder: @escaping (Category) -> Content) {
        self.viewModel = viewModel
        self.cellBuilder = cellBuilder
    }
    
    var body: some View {
        GeometryReader { geoProxy in
            ScrollViewReader { scrollProxy in
                PhotoLibraryModeView(viewModel: viewModel) {
                    LazyVGrid(columns: PhotoLibraryConstants.cardColumns, spacing: PhotoLibraryConstants.cardRowPadding) {
                        ForEach(viewModel.photoCategoryList) { category in
                            card(for: category, viewPortSize: geoProxy.size)
                        }
                    }
                    .padding(PhotoLibraryConstants.libraryPadding)
                }
                .onAppear {
                    DispatchQueue.main.async {
                        scrollProxy.scrollTo(viewModel.position, anchor: .center)
                    }
                }
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
                .frame(height: PhotoLibraryConstants.cardHeight)
        })
            .id(category.position)
            .buttonStyle(.plain)
            .frame(in: .named(PhotoLibraryConstants.scrollViewCoordinateSpaceName))
            .onPreferenceChange(FramePreferenceKey.self) { frame in
                Task { @MainActor in
                    viewModel.scrollTracker.trackFrame(frame, for: category, inViewPort: viewPortSize)
                }
            }
            .onAppear {
                viewModel.scrollTracker.trackAppearedPosition(category.position)
            }
            .onDisappear {
                viewModel.scrollTracker.trackDisappearedPosition(category.position)
            }
    }
}

import Foundation
import MEGASwiftUI
import SwiftUI

struct PhotoLibraryModeView<Category, VM: PhotoLibraryModeViewModel<Category>, Content: View>: View where Category: PhotoChronologicalCategory {
    @ObservedObject var viewModel: VM
    private let content: Content
    
    init(viewModel: VM, @ViewBuilder content: () -> Content) {
        self.viewModel = viewModel
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
                .offset(in: .named(PhotoLibraryConstants.scrollViewCoordinateSpaceName))
                .onPreferenceChange(OffsetPreferenceKey.self) { offset in
                    Task { @MainActor in
                        viewModel.scrollTracker.trackContentOffset(offset)
                    }
                }
        }
        .coordinateSpace(name: PhotoLibraryConstants.scrollViewCoordinateSpaceName)
    }
}

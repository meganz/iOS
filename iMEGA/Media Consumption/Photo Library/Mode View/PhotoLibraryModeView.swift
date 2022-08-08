import Foundation
import SwiftUI
import MEGASwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryModeView<Category, VM: PhotoLibraryModeViewModel<Category>, Content: View>: View where Category: PhotoChronologicalCategory {
    @ObservedObject var viewModel: VM
    private let content: Content
    
    init(viewModel: VM, @ViewBuilder content: () -> Content) {
        self.viewModel = viewModel
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            contentView()
                .offset(in: .named(PhotoLibraryConstants.scrollViewCoordinateSpaceName))
                .onPreferenceChange(OffsetPreferenceKey.self) {
                    viewModel.scrollTracker.trackContentOffset($0)
                }
        }
        .coordinateSpace(name: PhotoLibraryConstants.scrollViewCoordinateSpaceName)
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        if #available(iOS 15.0, *) {
            content
        } else {
            content
                .padding(.bottom, 60)
        }
    }
}

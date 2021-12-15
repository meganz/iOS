import Foundation
import SwiftUI

@available(iOS 14.0, *)
struct PhotoLibraryModeView<Category, VM: PhotoLibraryModeViewModel<Category>, Content: View>: View where Category: PhotosChronologicalCategory {
    @ObservedObject var viewModel: VM
    private let content: Content
    
    init(viewModel: VM, @ViewBuilder content: () -> Content) {
        self.viewModel = viewModel
        self.content = content()
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                content
                    .offset(in: .named("scrollView"))
            }
            .coordinateSpace(name: "scrollView")
            .onAppear {
                scrollProxy.scrollTo(viewModel.position)
            }
        }
    }
}

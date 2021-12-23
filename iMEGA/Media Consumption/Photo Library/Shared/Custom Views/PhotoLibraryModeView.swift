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
                contentView()
                    .offset(in: .named("scrollView"))
                    .onPreferenceChange(OffsetPreferenceKey.self) {
                        viewModel.scrollCalculator.recordContentOffset($0)
                    }
            }
            .coordinateSpace(name: "scrollView")
            .onAppear {
                DispatchQueue.main.async {
                    scrollProxy.scrollTo(viewModel.position, anchor: .center)
                }
            }
        }
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

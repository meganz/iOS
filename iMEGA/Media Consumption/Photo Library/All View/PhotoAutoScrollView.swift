import SwiftUI
import Combine

@available(iOS 14.0, *)
struct PhotoAutoScrollView: View {
    @StateObject var viewModel: PhotoAutoScrollViewModel
    let scrollProxy: ScrollViewProxy
    
    var body: some View {
        EmptyView()
            .onChange(of: viewModel.autoScroll) { _ in
                if viewModel.shouldAnimate {
                    withAnimation(.default.speed(3)) {
                        scrollProxy.scrollTo(viewModel.position, anchor: .center)
                    }
                } else {
                    scrollProxy.scrollTo(viewModel.position, anchor: .center)
                }
            }
    }
}

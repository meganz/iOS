import SwiftUI

@available(iOS 14.0, *)
struct ZoomViewModifier: ViewModifier {
    private let pinch = MagnificationGesture()
    
    @StateObject private var viewModel = ZoomViewModel()
    @Binding var zoomState: ZoomLevel
    
    var enable: Bool = true
    
    func body(content: Content) -> some View {
        content
            .highPriorityGesture(pinch.onEnded { scale in
                let nextState = next(in: scale > 1 ? .zoomIn : .zoomOut)
                
                if nextState != zoomState {
                    zoomState = nextState
                }
            }, including: enable ? .gesture : .subviews)
    }
    
    // MARK: - Private
    private func next(in action: ZoomAction) -> ZoomLevel {
        return viewModel.next(currentState: zoomState, action: action)
    }
}

@available(iOS 14.0, *)
extension View {
    func zoom(default level: Binding<ZoomLevel>, enable: Bool = true) -> some View {
        modifier(ZoomViewModifier(zoomState: level, enable: enable))
    }
}

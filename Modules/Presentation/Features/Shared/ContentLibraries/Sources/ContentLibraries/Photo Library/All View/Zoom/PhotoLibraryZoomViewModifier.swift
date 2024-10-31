import SwiftUI

struct ZoomViewModifier: ViewModifier {
    private let pinch = MagnificationGesture()
    
    @Environment(\.editMode) var editMode
    @Binding var zoomState: PhotoLibraryZoomState
    
    var enable: Bool = true
    
    func body(content: Content) -> some View {
        content
            .highPriorityGesture(pinch.onEnded { scale in
                scale > 1 ? zoomState.zoom(.in) : zoomState.zoom(.out)
            }, including: editMode?.wrappedValue.isEditing == true ? .subviews : .all)
    }
}

extension View {
    func zoom(_ state: Binding<PhotoLibraryZoomState>) -> some View {
        modifier(ZoomViewModifier(zoomState: state))
    }
}

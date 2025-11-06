import SwiftUI

struct PhotoLibraryZoomControlScrollTrackedOffsetViewModifier: ViewModifier {
    
    @ObservedObject var positionTracker: PhotoZoomControlPositionTracker
    
    func body(content: Content) -> some View {
        content
            .animation(.smooth, value: positionTracker.viewOffset)
            .offset(y: positionTracker.viewOffset)
    }
}

extension PhotoLibraryZoomControl {
    
    ///  Applies an animating offset to the View, based on the provided PositionTracker
    /// - Parameter positionTracker: PhotoZoomControlPositionTracker that determines the offset of the offset
    /// - Returns: A modified view that will update and animate its offset based on the provided values of PhotoZoomControlPositionTracker
    func offset(by positionTracker: PhotoZoomControlPositionTracker) -> some View {
        modifier(PhotoLibraryZoomControlScrollTrackedOffsetViewModifier(positionTracker: positionTracker))
    }
}

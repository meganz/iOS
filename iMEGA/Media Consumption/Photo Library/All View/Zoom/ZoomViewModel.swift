import Foundation

@available(iOS 14.0, *)
final class ZoomViewModel: ObservableObject {
    private var zoomLevelManagement = ZoomLevelManagement()
    
    func next(currentState state: ZoomLevel, action: ZoomAction) -> ZoomLevel {
        let nextZoomState = zoomLevelManagement.next(currentState: state, action: action)
        return nextZoomState
    }
}

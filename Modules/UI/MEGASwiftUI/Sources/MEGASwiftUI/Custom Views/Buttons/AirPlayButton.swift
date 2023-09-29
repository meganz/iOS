import AVKit
import SwiftUI

public struct AirPlayButton: UIViewRepresentable {
    private let backgroundColor: UIColor
    private let tintColor: UIColor
    private let activeTintColor: UIColor
    
    public init(
        backgroundColor: UIColor = .clear,
        tintColor: UIColor = .clear,
        activeTintColor: UIColor = .clear
    ) {
        self.backgroundColor = backgroundColor
        self.tintColor = tintColor
        self.activeTintColor = activeTintColor
    }
    
    public func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.backgroundColor = backgroundColor
        routePickerView.tintColor = tintColor
        routePickerView.activeTintColor = activeTintColor
        return routePickerView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {}
}

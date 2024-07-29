import SwiftUI
import UIKit

/// ViewModifier that attaches to a given view and publishes the initial and new events relating to the current devices UIDeviceOrientation.
private struct DeviceOrientationViewModifier: ViewModifier {
    
    let eventHandler: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                    eventHandler(.unknown)
                    return
                }
                
                switch windowScene.interfaceOrientation {
                case .unknown:
                    eventHandler(.unknown)
                case .portrait:
                    eventHandler(.portrait)
                case .portraitUpsideDown:
                    eventHandler(.portraitUpsideDown)
                case .landscapeLeft:
                    eventHandler(.landscapeLeft)
                case .landscapeRight:
                    eventHandler(.landscapeRight)
                @unknown default: 
                    eventHandler(.unknown)
                }
            }
            .onRotate { deviceOrientation in
                eventHandler(deviceOrientation)
            }
    }
}

public extension View {
    ///  Attaches a UIDeviceOrientation change listener. It will emit the initial orientation and all subsequent orientation changes.
    /// - Parameter eventHandler: Handler that will respond to orientation event
    /// - Returns: ViewModifier that monitors orientation changes.
    func onOrientationChanged(eventHandler: @escaping (UIDeviceOrientation) -> Void) -> some View {
        modifier(DeviceOrientationViewModifier(eventHandler: eventHandler))
    }
}

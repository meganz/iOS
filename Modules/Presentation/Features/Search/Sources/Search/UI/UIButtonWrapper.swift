import UIKit
import SwiftUI

/// Need to wrap an actual UIButton to be returned when context button is tapped.
/// It  is required to position popover on the iPad correctly
struct UIButtonWrapper: UIViewRepresentable {
    
    let image: UIImage
    let action: (UIButton) -> Void
    
    func makeUIView(context: Self.Context) -> UIButton {
        let uiButton = UIButton()
        context.coordinator.uiButton = uiButton
        context.coordinator.addTarget()
        uiButton.setImage(image, for: .normal)
        return uiButton
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIView(_ uiView: UIButton, context: Self.Context) {}
    
    class Coordinator: NSObject {
        var parent: UIButtonWrapper
        var uiButton = UIButton()
        
        init(_ uiView: UIButtonWrapper) {
            self.parent = uiView
        }
        
        func addTarget() {
            uiButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        }
        
        @objc func tapped() {
            self.parent.action(uiButton)
        }
    }
}

import SwiftUI
import UIKit

public struct ImageButtonWrapper: View {
    private struct InternalButtonWrapper: UIViewRepresentable {
        private let action: @MainActor (UIButton) -> Void

        public init(action: @escaping @MainActor (UIButton) -> Void) {
            self.action = action
        }

        public func makeUIView(context: Self.Context) -> UIButton {
            let uiButton = UIButton()
            context.coordinator.uiButton = uiButton
            context.coordinator.addTarget()
            return uiButton
        }

        public func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        public func updateUIView(_ uiView: UIButton, context: Self.Context) {}

        @MainActor
        public final class Coordinator: NSObject {
            var parent: InternalButtonWrapper
            var uiButton = UIButton()

            init(_ uiView: InternalButtonWrapper) {
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

    private let image: Image
    private let imageColor: Color
    private let action: @MainActor (UIButton) -> Void

    public init(
        image: Image,
        imageColor: Color,
        action: @escaping @MainActor (UIButton) -> Void
    ) {
        self.image = image
        self.imageColor = imageColor
        self.action = action
    }

    public var body: some View {
        ZStack {
            image
                .renderingMode(.template)
                .foregroundStyle(imageColor)
            InternalButtonWrapper(action: action)
        }
    }
}

/// Need to wrap an actual UIButton to be returned when context button is tapped.
/// It  is required to position popover on the iPad correctly
public struct UIButtonWrapper: UIViewRepresentable {
    
    private let image: UIImage
    private let action: (UIButton) -> Void
    
    public init(image: UIImage, action: @escaping (UIButton) -> Void) {
        self.image = image
        self.action = action
    }
    
    public func makeUIView(context: Self.Context) -> UIButton {
        let uiButton = UIButton()
        context.coordinator.uiButton = uiButton
        context.coordinator.addTarget()
        uiButton.setImage(image, for: .normal)
        return uiButton
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func updateUIView(_ uiView: UIButton, context: Self.Context) {}
    
    @MainActor
    public final class Coordinator: NSObject {
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

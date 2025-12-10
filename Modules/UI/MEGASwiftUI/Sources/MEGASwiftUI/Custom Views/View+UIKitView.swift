import SwiftUI
import UIKit

public extension View {
    func toUIView(hostingViewBackgroundColor: UIColor = .clear) -> UIView {
        let hostingController = UIHostingController(rootView: self)
        hostingController.view.backgroundColor = hostingViewBackgroundColor
        return hostingController.view
    }

    /// Wraps the SwiftUI View into a UIView that automatically sizes itself to fit the SwiftUI content.
    func toWrappedUIView(
        shouldEnableGlassEffect: Bool = false,
        padding edges: EdgeInsets = .init(top: 4.0, leading: 8.0, bottom: 4.0, trailing: 8.0)
    ) -> UIView {
        if #available(iOS 26.0, *), shouldEnableGlassEffect {
            let glassEffectView = self.padding(edges).glassEffect(.regular.interactive())
            return WrappedUIView(rootView: glassEffectView)
        } else {
            return WrappedUIView(rootView: self)
        }
    }
}

private final class WrappedUIView<Content: View>: UIView {
    private let hostingController: UIHostingController<Content>

    init(rootView: Content) {
        self.hostingController = UIHostingController(rootView: rootView)
        super.init(frame: .zero)

        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        hostingController.view.intrinsicContentSize
    }
}

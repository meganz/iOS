import MEGADesignToken
import SwiftUI

typealias AsyncViewAction = (UIView) async -> Void
typealias ViewAction = (UIView) -> Void

struct SimpleDialogConfig: Identifiable {
    
    struct ButtonModel: Identifiable {
        enum Theme {
            case primary
            case secondary
        }
        enum Action {
            case action(ViewAction)
            case asyncAction(AsyncViewAction)
        }
        
        var id: String {
            title
        }
        
        var title: String
        var theme: Theme
        var action: Action
    }
    init(
        imageResource: ImageResource,
        title: String,
        titleStyle: TitleStyle = .small,
        message: String,
        buttons: [ButtonModel],
        dismissAction: @escaping () -> Void
    ) {
        self.imageResource = imageResource
        self.title = title
        self.titleStyle = titleStyle
        self.message = message
        self.buttons = buttons
        self.dismissAction = dismissAction
    }
    
    enum TitleStyle {
        case large
        case small
    }
    var id: String {
        title + message + buttons.map(\.id).joined(separator: ",")
    }
    let imageResource: ImageResource
    let title: String
    let titleStyle: TitleStyle
    let message: String
    let buttons: [ButtonModel]
    let dismissAction: () -> Void
}

/// This view is intended to show a dialog to the user.
/// Can be wrapped in a UIKit view or used in SwiftUI directly.
/// It contains  image, title, description and  button for an action.
struct SimpleDialogView: View {
    @Environment(\.colorScheme) private var colorScheme
    let dialogConfig: SimpleDialogConfig
    
    @State var orientation = UIDevice.current.orientation
    
    let orientationChanged = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
        .makeConnectable()
        .autoconnect()
    
    init(dialogConfig: SimpleDialogConfig) {
        self.dialogConfig = dialogConfig
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(dialogConfig.imageResource)
                .resizable()
                .frame(width: 90, height: 90)
            titleView
                .foregroundStyle(TokenColors.Text.primary.swiftUI)
            Text(dialogConfig.message)
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(TokenColors.Text.secondary.swiftUI)
            ForEach(dialogConfig.buttons) { buttonModel in
                DialogButtonWrapper(
                    title: buttonModel.title,
                    theme: buttonModel.theme,
                    action: buttonModel.action
                )
                .frame(height: 50)
            }
        }
        .padding(30)
        .overlay(alignment: .top) {
            HStack {
                Spacer()
                Button {
                    dialogConfig.dismissAction()
                } label: {
                    Image(.closeBanner)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(TokenColors.Icon.secondary.swiftUI)
                }
            }
            .padding(.horizontal, 30)
            .opacity(orientation.isLandscape ? 1 : 0)
        }
        .onReceive(orientationChanged) { _ in
            orientation = UIDevice.current.orientation
        }
    }
    
    var titleView: Text {
        switch dialogConfig.titleStyle {
        case .large:
            Text(dialogConfig.title)
                .font(.headline)
        case .small:
            Text(dialogConfig.title)
                .font(.callout)
        }
    }
}

/// We are using a UIKit wrapped button to be able to present an iPad popover with correct source view
struct DialogButtonWrapper: UIViewRepresentable {
    
    let title: String
    var theme: SimpleDialogConfig.ButtonModel.Theme
    var action: SimpleDialogConfig.ButtonModel.Action
    
    func makeUIView(context: Self.Context) -> UIButton {
        let uiButton = UIButton()
        uiButton.setTitle(title, for: .normal)
        context.coordinator.uiButton = uiButton
        context.coordinator.addTarget()
        context.coordinator.action = action
        uiButton.layer.cornerRadius = 10
        uiButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        
        switch theme {
        case .primary:
            uiButton.backgroundColor = TokenColors.Button.primary
            uiButton.setTitleColor(TokenColors.Text.inverse, for: UIControl.State.normal)
        case .secondary:
            uiButton.backgroundColor = TokenColors.Button.secondary
            uiButton.setTitleColor(TokenColors.Text.accent, for: UIControl.State.normal)
        }
        
        return uiButton
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIView(_ uiView: UIButton, context: Self.Context) {}
    
    class Coordinator: NSObject {
        var parent: DialogButtonWrapper
        var uiButton = UIButton()
        var action: SimpleDialogConfig.ButtonModel.Action = .action({ _ in })
        
        init(_ uiView: DialogButtonWrapper) {
            self.parent = uiView
        }
        
        func addTarget() {
            uiButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
            uiButton.addTarget(self, action: #selector(alphaHalf), for: .touchDown)
            uiButton.addTarget(self, action: #selector(alphaOne), for: .touchCancel)
            uiButton.addTarget(self, action: #selector(alphaOne), for: .touchUpOutside)
            uiButton.addTarget(self, action: #selector(alphaOne), for: .touchUpInside)
        }
        
        @objc func alphaHalf() {
            uiButton.alpha = 0.5
        }
        
        @objc func alphaOne() {
            uiButton.alpha = 1.0
        }
        
        @objc func tapped() {
            switch action {
            case .action(let action):
                action(uiButton)
            case .asyncAction(let asyncAction):
                Task { @MainActor in
                    await asyncAction(uiButton)
                }
            }
        }
    }
}

 #Preview {
    let dialogConfig = SimpleDialogConfig(
        imageResource: .upgradeToProPlan,
        title: "Dialog title",
        message: "Fancy dialog message",
        buttons: [
            .init(
                title: "Button action title",
                theme: .primary,
                action: .action({_ in })
            )
        ],
        dismissAction: { }
    )
    
    VStack {
        SimpleDialogView(dialogConfig: dialogConfig)
            .colorScheme(.light)
        
        SimpleDialogView(dialogConfig: dialogConfig)
            .colorScheme(.dark)
    }
}

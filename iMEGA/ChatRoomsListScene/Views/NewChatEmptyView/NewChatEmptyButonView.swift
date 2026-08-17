import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct MenuCapableButton: View {
    var state: MenuButtonModel
    
    let height: CGFloat? = 50
    let maxWidth: CGFloat? = 288
    let cornerRadius: CGFloat = 10
    let font: Font = .headline.bold()
    
    var body: some View {
        Group {
            switch state.interaction {
            case .action(let action):
                buttonView(action)
            case .menu(let menu):
                menuView(menu)
            }
        }
        .disabled(!state.isEnabled)
    }
    
    func menuView(_ menus: [MenuButtonModel.Menu]) -> some View {
        Menu {
            ForEach(menus) { menu in
                Button {
                    menu.action()
                } label: {
                    Label {
                        Text(menu.name)
                    } icon: {
                        menu.image
                    }
                }
            }
        } label: {
            text
                .font(font)
        }
    }
    
    private func buttonView(_ action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            text
                .font(font)
        }
    }
    
    @ViewBuilder
    private var text: some View {
        if !state.isEnabled {
            disabledText
        } else {
            switch state.theme {
            case .dark:
                PrimaryActionButtonViewText(title: state.title)
                .frame(maxWidth: maxWidth)
                .frame(height: height)
            case .light:
                SecondaryActionButtonViewText(title: state.title)
                .frame(maxWidth: maxWidth)
                .frame(height: height)
            }
        }
    }

    /// Both themes share the same disabled appearance, the one `MEGAButton` gives its disabled state.
    private var disabledText: some View {
        Text(state.title)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(TokenColors.Text.onColorDisabled.swiftUI)
            .background(TokenColors.Button.disabled.swiftUI)
            .cornerRadius(cornerRadius)
            .frame(maxWidth: maxWidth)
            .frame(height: height)
    }
}

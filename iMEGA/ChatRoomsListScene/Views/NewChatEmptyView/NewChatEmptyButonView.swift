import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct MenuCapableButton: View {
    var state: MenuButtonModel
    
    var height: CGFloat? = 50
    var maxWidth: CGFloat? = 288
    var cornerRadius: CGFloat = 10
    var font: Font = .headline
    
    var body: some View {
        switch state.interaction {
        case .action(let action):
            buttonView(action)
        case .menu(let menu):
            menuView(menu)
        }
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
                        Image(menu.image)
                    }
                }
            }
        } label: {
            text
        }
    }
    
    private func buttonView(_ action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            text
        }
    }
    
    @ViewBuilder
    private var text: some View {
        switch state.theme {
        case .dark:
            PrimaryActionButtonViewText(
                title: state.title,
                isDesignTokenEnabled: isDesignTokenEnabled
            )
            .frame(maxWidth: maxWidth)
            .frame(height: height)
        case .light:
            SecondaryActionButtonViewText(
                title: state.title,
                isDesignTokenEnabled: isDesignTokenEnabled
            )
            .frame(maxWidth: maxWidth)
            .frame(height: height)
        }
    }
}

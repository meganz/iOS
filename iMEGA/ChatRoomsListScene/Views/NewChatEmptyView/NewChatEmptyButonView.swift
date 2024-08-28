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

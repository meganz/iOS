import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct ChatRoomsEmptyBottomButtonView: View {
    let name: String
    var height: CGFloat? = 50
    var backgroundColor: Color { TokenColors.Icon.accent.swiftUI }
    var textColor: Color { TokenColors.Text.inverseAccent.swiftUI }
    var maxWidth: CGFloat? = 288
    var cornerRadius: CGFloat = 10
    var font: Font = .headline
    var menus: [MenuButtonModel.Menu]?
    var action: (() -> Void)?
    
    var body: some View {
        if let menus {
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
                Text(name)
                    .frame(maxWidth: maxWidth)
                    .frame(height: height)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(cornerRadius)
                    .font(font)
            }
        } else {
            Button {
                action?()
            } label: {
                Text(name)
                    .frame(maxWidth: maxWidth)
                    .frame(height: height)
                    .background(backgroundColor)
                    .foregroundColor(textColor)
                    .cornerRadius(cornerRadius)
                    .font(font)
            }
        }
    }
}

import MEGADesignToken
import MEGASwiftUI
import SwiftUI

struct ChatRoomsEmptyBottomButtonView: View {
    let name: String
    var height: CGFloat? = 50
    var backgroundColor: Color { isDesignTokenEnabled ? TokenColors.Icon.accent.swiftUI : Color(red: 0, green: 0.66, blue: 0.52) }
    var textColor: Color { isDesignTokenEnabled ? TokenColors.Text.inverseAccent.swiftUI : MEGAAppColor.White._FFFFFF.color }
    var maxWidth: CGFloat? = 288
    var cornerRadius: CGFloat = 10
    let isDesignTokenEnabled: Bool
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

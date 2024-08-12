import MEGADesignToken
import SwiftUI

struct ChatRoomsEmptyView: View {
    let emptyViewState: ChatRoomsEmptyViewState
    let isDesignTokenEnabled: Bool
    
    var body: some View {
        VStack {
            if let archivedChatsViewState = emptyViewState.archivedChats {
                ChatRoomsTopRowView(state: archivedChatsViewState)
                    .onTapGesture {
                        archivedChatsViewState.action()
                    }
                    .padding(8)
                Divider()
                    .padding(.leading)
            }
            
            if let contactsOnMega = emptyViewState.contactsOnMega {
                ChatRoomsTopRowView(state: contactsOnMega)
                    .onTapGesture {
                        contactsOnMega.action()
                    }
                    .padding(8)
            }
            
            VStack {
                Spacer()
                
                ChatRoomsEmptyCenterView(
                    imageResource: emptyViewState.centerImageResource,
                    title: emptyViewState.centerTitle,
                    description: emptyViewState.centerDescription
                )
                
                Spacer()
                
                if let buttonTitle = emptyViewState.bottomButtonTitle {
                    ChatRoomsEmptyBottomButtonView(
                        name: buttonTitle,
                        isDesignTokenEnabled: isDesignTokenEnabled,
                        menus: emptyViewState.bottomButtonMenus,
                        action: emptyViewState.bottomButtonAction
                    )
                    .padding(.horizontal, 70)
                    
                    Rectangle()
                        .fill(.clear)
                        .frame(maxWidth: .infinity, maxHeight: 35)
                }
            }
        }
        .background(.clear)
    }
}

private struct ChatRoomsEmptyCenterView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let imageResource: ImageResource
    let title: String
    let description: String?
    
    var body: some View {
        VStack {
            if verticalSizeClass != .compact {
                Image(imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .tint(TokenColors.Icon.secondary.swiftUI)
            }
            
            Text(title)
                .font(.body)
                .padding(.bottom, 5)
                .foregroundColor(TokenColors.Text.primary.swiftUI)
            
            if let description {
                Text(description)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .foregroundColor(TokenColors.Text.primary.swiftUI)
            }
        }
    }
}

private struct ChatRoomsEmptyBottomButtonView: View {
    let name: String
    var height: CGFloat? = 50
    var backgroundColor: Color { isDesignTokenEnabled ? TokenColors.Icon.accent.swiftUI : Color(red: 0, green: 0.66, blue: 0.52) }
    var textColor: Color { isDesignTokenEnabled ? TokenColors.Text.inverseAccent.swiftUI : MEGAAppColor.White._FFFFFF.color }
    var maxWidth: CGFloat? = 288
    var cornerRadius: CGFloat = 10
    let isDesignTokenEnabled: Bool
    var font: Font = .headline
    var menus: [ChatRoomsEmptyBottomButtonMenu]?
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

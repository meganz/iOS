import SwiftUI

struct ChatRoomsEmptyView: View {
    let emptyViewState: ChatRoomsEmptyViewState
    
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
                
                ChatRoomsEmptyCenterView(imageAsset: emptyViewState.centerImageAsset,
                                         title: emptyViewState.centerTitle,
                                         description: emptyViewState.centerDescription)
                
                Spacer()
                
                if let buttonTitle = emptyViewState.bottomButtonTitle {
                    ChatRoomsEmptyBottomButtonView(
                        name: buttonTitle,
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
    }
}

fileprivate struct ChatRoomsEmptyCenterView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    let imageAsset: ImageAsset?
    let title: String
    let description: String?
    
    var body: some View {
        VStack {
            if verticalSizeClass != .compact,
                let imageAsset,
                let image = Image(uiImage: UIImage(asset: imageAsset)) {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            }
            
            Text(title)
                .font(.body)
                .padding(.bottom, 5)
            
            if let description {
                Text(description)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }
        }
    }
}

fileprivate struct ChatRoomsEmptyBottomButtonView: View {
    let name: String
    var height: CGFloat? = 50
    var backgroundColor = Color(red: 0, green: 0.66, blue: 0.52)
    var textColor = Color.white
    var maxWidth: CGFloat? = 288
    var cornerRadius: CGFloat = 10
    var font: Font = .headline
    var menus: [ChatRoomsEmptyBottomButtonMenu]? = nil
    var action: (() -> Void)? = nil

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
                            Image(uiImage: UIImage(asset: menu.image))
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
            Button(name) {
                action?()
            }
            .frame(maxWidth: maxWidth)
            .frame(height: height)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(cornerRadius)
            .font(font)
        }
    }
}


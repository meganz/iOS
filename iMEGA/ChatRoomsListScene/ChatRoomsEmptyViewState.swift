
struct ChatRoomsEmptyViewState {
    let topRowImageAsset: ImageAsset?
    let topRowDescription: String?
    let topRowAction: (() -> Void)?
    
    let centerImageAsset: ImageAsset
    let centerTitle: String
    let centerDescription: String

    let bottomButtonTitle: String?
    let bottomButtonAction: (() -> Void)?
    
    let bottomButtonMenus: [ChatRoomsEmptyBottomButtonMenu]?
}


struct ChatRoomsEmptyBottomButtonMenu {
    let name: String
    let image: ImageAsset
    let action: () -> Void
}

extension ChatRoomsEmptyBottomButtonMenu: Identifiable {
    var id: String {
        name
    }
}

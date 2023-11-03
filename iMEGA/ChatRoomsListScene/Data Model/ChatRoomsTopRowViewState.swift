struct ChatRoomsTopRowViewState {
    let image: UIImage
    let description: String
    let rightDetail: String?
    let action: (() -> Void)
    
    init(image: UIImage, description: String, rightDetail: String? = nil, action: @escaping () -> Void) {
        self.image = image
        self.description = description
        self.rightDetail = rightDetail
        self.action = action
    }
}

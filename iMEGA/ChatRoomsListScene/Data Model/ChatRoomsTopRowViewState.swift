
struct ChatRoomsTopRowViewState {
    let image: UIImage
    let imageTintColor: UIColor?
    let description: String
    let rightDetail: String?
    let action: (() -> Void)
    
    init(image: UIImage, imageTintColor: UIColor? = nil, description: String, rightDetail: String? = nil, action: @escaping () -> Void) {
        self.image = image
        self.imageTintColor = imageTintColor
        self.description = description
        self.rightDetail = rightDetail
        self.action = action
    }
}

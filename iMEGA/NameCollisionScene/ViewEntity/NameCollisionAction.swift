
struct NameCollisionAction: Identifiable {
    let id = UUID()
    var actionType: NameCollisionActionType
    var name: String?
    var size: String?
    var date: String?
    var isFile: Bool
    var imageUrl: URL?
    var itemPlaceholder: String
}

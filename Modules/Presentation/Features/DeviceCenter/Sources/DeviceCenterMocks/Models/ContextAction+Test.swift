import DeviceCenter

public extension ContextAction {
    init(
        type: ContextAction.Category,
        isTesting: Bool = true
    ) {
        self.init(type: type, title: "", icon: "")
    }
}

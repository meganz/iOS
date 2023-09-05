import DeviceCenter

public extension DeviceCenterAction {
    init(
        type: DeviceCenterActionType,
        isTesting: Bool = true
    ) {
        self.init(type: type, title: "", icon: "", action: {})
    }
}

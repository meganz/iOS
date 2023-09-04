public struct DeviceListAssets {
    public let title: String
    public let currentDeviceTitle: String
    public let otherDevicesTitle: String
    public let deviceDefaultName: String
    
    public init(title: String, currentDeviceTitle: String, otherDevicesTitle: String, deviceDefaultName: String) {
        self.title = title
        self.currentDeviceTitle = currentDeviceTitle
        self.otherDevicesTitle = otherDevicesTitle
        self.deviceDefaultName = deviceDefaultName
    }
}

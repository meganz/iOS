import MEGADomain

///  `SelectedDevice` is an utility struct to keep track of all the important data about a device that a user picks from the `DeviceList` inside the `Device Center`. This helps keep the code clean and easy to handle, avoiding endless lists of properties in the init of Routers and View Models.
public struct SelectedDevice {
    public var id: String // A unique identifier for the selected device.
    public var name: String // The name of the selected device.
    public let icon: String // The name of the selected device icon.
    public let isCurrent: Bool // A boolean indicating whether the selected device is the one currently being used.
    public let isNewDeviceWithoutCU: Bool // A boolean indicating whether the selected device is a new device, where camera uploads have never been enabled previously.
    public var backups: [BackupEntity] // List of backups, sync and cu folders belonging to the selected device.
    
    // A boolean that determines if the selected device is a mobile device (iPhone, or iPad) by evaluating if among the list of backups, sync and cu folders there is a backup of type camera uploads or media uploads.
    public var isMobile: Bool {
        backups.contains {
            $0.type == .cameraUpload || $0.type == .mediaUpload
        }
    }
    
    public init(
        id: String,
        name: String,
        icon: String,
        isCurrent: Bool,
        isNewDeviceWithoutCU: Bool,
        backups: [BackupEntity] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.isCurrent = isCurrent
        self.isNewDeviceWithoutCU = isNewDeviceWithoutCU
        self.backups = backups
    }
}

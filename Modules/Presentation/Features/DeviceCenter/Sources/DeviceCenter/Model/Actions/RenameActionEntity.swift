public typealias RenamingFinished = () -> Void

public struct RenameActionEntity {
    public let deviceId: String
    public let deviceOldName: String
    public let otherDeviceNames: [String]
    public let renamingFinished: RenamingFinished
    
    public init(deviceId: String, deviceOldName: String, otherDeviceNames: [String], renamingFinished: @escaping RenamingFinished) {
        self.deviceId = deviceId
        self.deviceOldName = deviceOldName
        self.otherDeviceNames = otherDeviceNames
        self.renamingFinished = renamingFinished
    }
}

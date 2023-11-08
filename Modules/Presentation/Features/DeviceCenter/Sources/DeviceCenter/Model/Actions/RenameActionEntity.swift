public typealias RenamingFinished = () -> Void

public struct RenameActionEntity {
    public let deviceId: String
    public let deviceOldName: String
    public let maxCharacters: Int
    public let otherDeviceNames: [String]
    public let renamingFinished: RenamingFinished
    
    public init(
        deviceId: String,
        deviceOldName: String,
        maxCharacters: Int = 32,
        otherDeviceNames: [String],
        renamingFinished: @escaping RenamingFinished)
    {
        self.deviceId = deviceId
        self.deviceOldName = deviceOldName
        self.maxCharacters = maxCharacters
        self.otherDeviceNames = otherDeviceNames
        self.renamingFinished = renamingFinished
    }
}

import MEGADomain
import MEGASdk
import MEGASwift

public struct DeviceCenterRepository: DeviceCenterRepositoryProtocol {
    public static var newRepo: DeviceCenterRepository {
        DeviceCenterRepository(sdk: MEGASdk.sharedSdk)
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func fetchUserDevices() async -> [DeviceEntity] {
        let devices = await fetchUserDeviceNames()
        let userBackups = await fetchUserBackups()
        let userGroupedBackups = Dictionary(grouping: userBackups, by: \.deviceId)
        
        return devices.compactMap { device in
            guard let deviceBackups = userGroupedBackups[device.id],
                    deviceBackups.isNotEmpty else { return nil }
            
            var updatedDevice = device
            updatedDevice.backups = deviceBackups
            return updatedDevice
        }
    }
    
    private func fetchUserBackups() async -> [BackupEntity] {
        await withAsyncValue(in: { completion in
            sdk.getBackupInfo(RequestDelegate(completion: { result in
                if case let .success(request) = result {
                    completion(.success(request.backupInfoList.toBackupInfoEntities()))
                } else {
                    completion(.success([]))
                }
            }))
        })
    }
    
    private func fetchUserDeviceNames() async -> [DeviceEntity] {
        await withAsyncValue(in: { completion in
            sdk.getUserAttributeType(.deviceNames, delegate: RequestDelegate { (result) in
                if case let .success(request) = result {
                    guard let devicesDictionary = request.megaStringDictionary else { return }
                    
                    let devices = devicesDictionary.compactMap { (key, value) -> DeviceEntity? in
                        guard let deviceName = value.base64URLDecoded else { return nil }
                        return DeviceEntity(id: key, name: deviceName)
                    }
                    
                    completion(.success(devices))
                } else {
                    completion(.success([]))
                }
            })
        })
    }
}

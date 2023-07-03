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
    
    public func backups() async throws -> [BackupEntity] {
        let devices = await fetchUserDevices()
        return try await withAsyncThrowingValue(in: { completion in
            sdk.getBackupInfo(RequestDelegate(completion: { result in
                switch result {
                case .success(let request):
                    let backups = request.backupInfoList
                        .toBackupInfoEntities()
                        .map { backup in
                            if let deviceEntity = devices.first(where: { $0.id == backup.deviceId }) {
                                var updatedBackup = backup
                                updatedBackup.device = deviceEntity
                                return updatedBackup
                            }
                            return backup
                        }

                    completion(.success(backups))
                case .failure:
                    completion(.failure(GenericErrorEntity()))
                }
            }))
        })
    }
    
    private func fetchUserDevices() async -> [DeviceEntity] {
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

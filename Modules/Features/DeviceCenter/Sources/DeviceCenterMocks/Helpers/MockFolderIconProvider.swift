import DeviceCenter
import MEGADomain

public final class MockFolderIconProvider: FolderIconProviding {
    private var stubbedIconName: String

    public init(stubbedIconName: String = "") {
        self.stubbedIconName = stubbedIconName
    }

    public func iconName(for backupType: BackupTypeEntity) -> String? {
        stubbedIconName
    }
}

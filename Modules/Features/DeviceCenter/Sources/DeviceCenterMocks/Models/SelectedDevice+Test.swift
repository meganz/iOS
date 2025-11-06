import DeviceCenter
import MEGADomain

public extension SelectedDevice {
    init(
       id: String = "",
       name: String = "",
       icon: String = "",
       isCurrent: Bool = false,
       isNewDeviceWithoutCU: Bool = false,
       backups: [BackupEntity],
       isTesting: Bool = true
   ) {
       self.init(
        id: id,
        name: name,
        icon: icon,
        isCurrent: isCurrent,
        isNewDeviceWithoutCU: isNewDeviceWithoutCU,
        backups: backups
       )
   }
}

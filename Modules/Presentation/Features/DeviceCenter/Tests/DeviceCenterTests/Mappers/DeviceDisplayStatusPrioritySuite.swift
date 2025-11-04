@testable import DeviceCenter
import MEGADomain
import Testing

@Suite("Device Display Status Priority Resolution")
struct DeviceDisplayStatusPrioritySuite {

    @Test("inactive beats paused and upToDate -> .inactive")
    func inactiveBeatsOthers() {
        let device = deviceWithStatuses([.upToDate, .paused, .inactive])
        #expect(device.backups?.toDeviceDisplayStatus() == .inactive)
    }

    @Test("error beats disabled, paused, updating, upToDate -> .attentionNeeded")
    func errorBeatsOthers() {
        let device = deviceWithStatuses([.error, .disabled, .paused, .updating, .upToDate])
        #expect(device.backups?.toDeviceDisplayStatus() == .attentionNeeded)
    }

    @Test("disabled (CU) beats paused, updating, upToDate -> .attentionNeeded")
    func disabledCUBeatsOthers() {
        let device = deviceWithFixtures([
            .init(type: .cameraUpload, status: .disabled),
            .init(type: .twoWay, status: .paused),
            .init(type: .twoWay, status: .updating),
            .init(type: .twoWay, status: .upToDate)
        ])
        #expect(device.backups?.toDeviceDisplayStatus() == .attentionNeeded)
    }

    @Test("paused (non-CU) beats updating and upToDate -> .attentionNeeded")
    func pausedBeatsUpdatingAndUpToDate() {
        let device = deviceWithStatuses([.paused, .updating, .upToDate])
        #expect(device.backups?.toDeviceDisplayStatus() == .attentionNeeded)
    }

    @Test("updating beats upToDate -> .updating")
    func updatingBeatsUpToDate() {
        let device = deviceWithStatuses([.updating, .upToDate])
        #expect(device.backups?.toDeviceDisplayStatus() == .updating)
    }

    @Test("only upToDate -> .upToDate")
    func onlyUpToDate() {
        let device = deviceWithStatuses([.upToDate])
        #expect(device.backups?.toDeviceDisplayStatus() == .upToDate)
    }

    @Test("only noCameraUploads -> .noCameraUploads")
    func onlyNoCameraUploads() {
        let device = deviceWithFixtures([
            .init(type: .cameraUpload, status: .noCameraUploads)
        ])
        #expect(device.backups?.toDeviceDisplayStatus() == .noCameraUploads)
    }

    private func deviceWithStatuses(_ statuses: [BackupStatusEntity]) -> DeviceEntity {
        let backups = statuses.map { status -> BackupEntity in
            var backup = BackupEntity(type: .twoWay)
            backup.backupStatus = status
            return backup
        }
        return DeviceEntity(id: "device", name: "Device", backups: backups, status: .upToDate)
    }

    private func deviceWithFixtures(_ fixtures: [BackupFixture]) -> DeviceEntity {
        let backups = fixtures.map { fixture -> BackupEntity in
            var backup = BackupEntity(type: fixture.type)
            backup.backupStatus = fixture.status
            return backup
        }
        return DeviceEntity(id: "device", name: "Device", backups: backups, status: .upToDate)
    }

    private struct BackupFixture {
        let type: BackupTypeEntity
        let status: BackupStatusEntity
    }
}

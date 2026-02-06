import MEGADomain
import MEGASdk

extension UploadOptionsEntity {
    public func toMEGAUploadOptions() -> MEGAUploadOptions {
        MEGAUploadOptions(
            fileName: fileName,
            mtime: mtime,
            appData: appData,
            isSourceTemporary: isSourceTemporary,
            startFirst: startFirst,
            pitagTrigger: pitagTrigger.toMEGAPitagTrigger(),
            isChatUpload: isChatUpload,
            pitagTarget: pitagTarget.toMEGAPitagTarget()
        )
    }
}

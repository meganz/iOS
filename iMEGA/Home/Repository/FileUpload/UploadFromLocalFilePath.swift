import Foundation

struct UploadFromLocalFilePath {
    var upload: (
        _ localFilePath: String,
        _ parentNodeHandle: MEGAHandle
    ) throws -> Void
}

extension UploadFromLocalFilePath {

    static var live: Self {
        let fileManager = FileManager.default
        let megaSDK = MEGASdkManager.sharedMEGASdk()

        return Self { (localFilePath, parentNodeHandle) in
            guard let fileFingerprint = megaSDK.fingerprint(forFilePath: localFilePath) else {
                throw UploadFromLocalPathError.errorCreatingFileFingerprint
            }

            guard let parentNode = megaSDK.node(forHandle: parentNodeHandle) else {
                throw UploadFromLocalPathError.errorFindParentNodeFolder
            }

            guard let node = megaSDK.node(forFingerprint: fileFingerprint, parent: parentNode) else {
                // In this case, there is no node has same fingerprint
                let coordinates = (localFilePath as NSString).mnz_coordinatesOfPhotoOrVideo()
                let appData = coordinates.map(NSString().mnz_appData(toSaveCoordinates:))
                megaSDK.startUpload(
                    withLocalPath: localFilePath,
                    parent: parentNode,
                    appData: appData,
                    isSourceTemporary: true
                )
                return
            }

            if node.parentHandle == parentNodeHandle {
                // Same file, under same folder
                try fileManager.removeItem(atPath: localFilePath)
            } else if let name = node.name {
                // The file exists but within a different folder, copy across with a same name
                megaSDK.copy(node, newParent: parentNode, newName: name)
            }
        }
    }
}

enum UploadFromLocalPathError: Error {
    case errorCreatingFileFingerprint
    case errorFindParentNodeFolder
}

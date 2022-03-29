import Foundation

struct UploadFromURL {

    var upload: (
        _ fileURL:URL,
        _ parentNodeHandle: MEGAHandle
    ) throws -> Void
}

extension UploadFromURL {

    static var live: Self {
        let fileManager: FileManager = FileManager.default
        let megaSDK: MEGASdk = MEGASdkManager.sharedMEGASdk()
        let uploadDirectory: NSString = fileManager.uploadsDirectory() as NSString

        return Self { (url, parentNodeHandle) -> Void in
            let localFilePath = uploadDirectory.appendingPathComponent(url.lastPathComponent)
            try? fileManager.moveItem(atPath: url.path, toPath: localFilePath)

            guard let fileFingerprint = megaSDK.fingerprint(forFilePath: localFilePath),
                  let parentNode = megaSDK.node(forHandle: parentNodeHandle) else {
                return
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
            // The file exists but within a different folder
            guard node.parentHandle == parentNodeHandle else {
                megaSDK.copy(node, newParent: parentNode, newName: url.lastPathComponent)
                return
            }

            // Same file, under same folder
            try fileManager.removeItem(atPath: localFilePath)
        }
    }
}

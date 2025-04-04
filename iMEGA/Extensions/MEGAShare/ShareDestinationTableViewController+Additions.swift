import MEGAAppSDKRepo

extension ShareDestinationTableViewController {
    @objc func initializeCameraUploadsNode() {
        CameraUploadNodeAccess.shared.loadNode()
    }
}

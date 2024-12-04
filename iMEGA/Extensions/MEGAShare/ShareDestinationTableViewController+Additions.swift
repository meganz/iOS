import MEGASDKRepo

extension ShareDestinationTableViewController {
    @objc func initializeCameraUploadsNode() {
        CameraUploadNodeAccess.shared.loadNode()
    }
}

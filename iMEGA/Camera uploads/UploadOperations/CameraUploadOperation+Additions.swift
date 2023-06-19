extension CameraUploadOperation {
    @objc func prepareThumbnailAndPreviewFiles() async -> Bool {
        if isCancelled {
            finish(with: .cancelled)
            return false
        }
        
        let fileAttributeGenerator = FileAttributeGenerator(sourceURL: uploadInfo.attributeImageURL,
                                                            pixelWidth: uploadInfo.asset.pixelWidth,
                                                            pixelHeight: uploadInfo.asset.pixelHeight)
        
        let thumbnailCreated = await fileAttributeGenerator.createThumbnail(at: uploadInfo.thumbnailURL)
        if isCancelled {
            finish(with: .cancelled)
            return false
        }
        if !thumbnailCreated {
            return false
        }
        
        let previewCreated = await fileAttributeGenerator.createPreview(at: uploadInfo.previewURL)
        return previewCreated
    }
}

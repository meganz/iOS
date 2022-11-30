import SDWebImage

extension UIPasteboard {
    func loadImage() -> UIImage? {
        return decodeWebPImageIfNeeded() ?? UIPasteboard.general.image
    }
    
    private func decodeWebPImageIfNeeded() -> UIImage? {
        let webPIdentifier = UTType.webP.identifier
        if types.contains(webPIdentifier) && image == nil {
            let data = data(forPasteboardType: webPIdentifier)
            return SDImageAWebPCoder.shared.decodedImage(with: data, options: nil)
        } else {
            return nil
        }
    }
}

import SDWebImage

extension UIPasteboard {
    func loadImage() -> UIImage? {
        if #available(iOS 14.0, *) {
            return decodeWebPImageIfNeeded() ?? UIPasteboard.general.image
        }
        return UIPasteboard.general.image
    }
    
    @available(iOS 14.0, *)
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

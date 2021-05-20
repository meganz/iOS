import SDWebImage

extension UIPasteboard {
    func loadImage() -> UIImage? {
        if #available(iOS 14.0, *) {
            if types.contains(UTType.webP.identifier),
               image == nil,
               let data = data(forPasteboardType: UTType.webP.identifier) {
                return SDImageAWebPCoder.shared.decodedImage(with: data, options: nil)
            }
        }
        return UIPasteboard.general.image
    }
}

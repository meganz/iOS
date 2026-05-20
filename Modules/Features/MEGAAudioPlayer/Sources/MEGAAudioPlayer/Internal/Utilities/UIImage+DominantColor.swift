import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

extension UIImage {
    /// Average color of the image across all pixels — used as the "dominant" tint
    /// driving the audio player's background glow.
    ///
    /// `CIAreaAverage` is GPU-accelerated and returns the result as a single-pixel
    /// CIImage. The average is not the strict mode (most-frequent color), but for
    /// a soft, blurred halo at low opacity it is visually indistinguishable while
    /// being orders of magnitude cheaper than k-means clustering.
    var mnz_dominantColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }

        let filter = CIFilter.areaAverage()
        filter.inputImage = inputImage
        filter.extent = inputImage.extent

        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: 1
        )
    }
}

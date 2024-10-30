import Photos
import PhotosUI

@MainActor
public protocol MEGAPhotoPickerProtocol {
    /// Asynchronously presents a picker and returns an array of `PHAsset` representing the assets picked by the user.
    /// If user taps cancel, this funtion will return an empty array
    func pickAssets() async -> [PHAsset]
}

public final class MEGAPhotoPicker: MEGAPhotoPickerProtocol {
    private var photoPickerDelegate: PhotoPickerDelegate?
    private weak var presenter: UIViewController?
    
    public init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    public func pickAssets() async -> [PHAsset] {
        return await withCheckedContinuation { continuation in
            var pickerConfiguration = PHPickerConfiguration(photoLibrary: .shared())
            pickerConfiguration.preferredAssetRepresentationMode = .automatic
            pickerConfiguration.selection = .default
            pickerConfiguration.selectionLimit = 0
            
            let picker = PHPickerViewController(configuration: pickerConfiguration)
            let delegate = PhotoPickerDelegate { assets in
                continuation.resume(returning: assets)
            }
            self.photoPickerDelegate = delegate
            picker.delegate = delegate
            
            presenter?.present(picker, animated: true)
        }
    }
}

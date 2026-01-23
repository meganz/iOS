import Photos
import PhotosUI

@MainActor
public protocol MEGAPhotoPickerProtocol {
    /// Asynchronously presents a picker and returns a tuple of `PHAsset` and the original number of selected items.
    /// If user taps cancel, this funtion will return an empty array and zero count
    func pickAssets() async -> (assets: [PHAsset], selectedCount: Int)
}

public final class MEGAPhotoPicker: MEGAPhotoPickerProtocol {
    private var photoPickerDelegate: PhotoPickerDelegate?
    private weak var presenter: UIViewController?
    
    public init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    public func pickAssets() async -> (assets: [PHAsset], selectedCount: Int) {
        return await withCheckedContinuation { continuation in
            var pickerConfiguration = PHPickerConfiguration(photoLibrary: .shared())
            pickerConfiguration.preferredAssetRepresentationMode = .automatic
            pickerConfiguration.selection = .default
            pickerConfiguration.selectionLimit = 0
            
            let picker = PHPickerViewController(configuration: pickerConfiguration)
            let delegate = PhotoPickerDelegate { assets, selectedCount in
                continuation.resume(returning: (assets, selectedCount))
            }
            self.photoPickerDelegate = delegate
            picker.delegate = delegate
            
            presenter?.present(picker, animated: true)
        }
    }
}

import Photos
import PhotosUI

@MainActor
public protocol MEGAPhotoPickerProtocol {
    /// Asynchronously presents a picker and returns a tuple of `PHAsset` and the original number of selected items.
    /// If user taps cancel, this funtion will return an empty array and zero count
    func pickAssets() async -> (assets: [PHAsset], selectedCount: Int)
    
    /// Asynchronously presents a photo picker and returns an array of `PHPickerResult` representing the raw picker results selected by the user.
    /// If the user taps cancel, this function will return an empty array.
    ///
    /// Unlike `pickAssets()`, this method returns `PHPickerResult` objects which provide access to the selected items without requiring Photos library authorization.
    /// This is useful when you need to work with the raw picker results or want to avoid requesting full photo library access.
    ///
    /// - Returns: An array of `PHPickerResult` objects representing the items selected by the user, or an empty array if the user cancels.
    func pickResults() async -> [PHPickerResult]
}

public final class MEGAPhotoPicker: MEGAPhotoPickerProtocol {
    private var photoPickerDelegate: PhotoPickerDelegate?
    private weak var presenter: UIViewController?
    
    public init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    public func pickAssets() async -> (assets: [PHAsset], selectedCount: Int) {
        return await withCheckedContinuation { continuation in
            let picker = makePicker()
            let delegate = PhotoPickerDelegate { assets, selectedCount in
                continuation.resume(returning: (assets, selectedCount))
            }
            self.photoPickerDelegate = delegate
            picker.delegate = delegate
            
            presenter?.present(picker, animated: true)
        }
    }
    
    public func pickResults() async -> [PHPickerResult] {
        return await withCheckedContinuation { continuation in
            // Apple's end that was causing bulk uploads to hang/never complete.
            // As a mitigation, we capped it to 400 at a time.
            // .current to avoid transcoding if possible. .automatic takes too much time
            // loading the items.
            let picker = makePicker(selectionLimit: 400, mode: .current)
            let delegate = PhotoPickerDelegate(completion: nil) { results in
                nonisolated(unsafe) let safeResults = results
                continuation.resume(returning: safeResults)
            }
            self.photoPickerDelegate = delegate
            picker.delegate = delegate
            picker.presentationController?.delegate = delegate
            
            presenter?.present(picker, animated: true)
        }
    }
    
    // MARK: - Private
    
    private func makePicker(
        selectionLimit: Int = 0,
        mode: PHPickerConfiguration.AssetRepresentationMode = .automatic
    ) -> PHPickerViewController {
        var pickerConfiguration = PHPickerConfiguration(photoLibrary: .shared())
        pickerConfiguration.preferredAssetRepresentationMode = mode
        pickerConfiguration.selection = .default
        pickerConfiguration.selectionLimit = selectionLimit
        return PHPickerViewController(configuration: pickerConfiguration)
    }
}

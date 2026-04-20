import Photos
import PhotosUI

@MainActor
public protocol MEGAPhotoPickerProtocol {
    /// Presents a photo picker and returns the selected assets via completion.
    /// Requires Photos library authorization. If the user cancels, completion is called with an empty array and zero count.
    /// - Parameter completion: Called with the resolved `PHAsset` array and the original number of selected items.
    func pickAssets(completion: @escaping ([PHAsset], Int) -> Void)

    /// Presents a photo picker and returns raw picker results via completion, without requiring Photos library authorization.
    /// If the user cancels, completion is called with an empty array.
    /// - Parameter completion: Called with the `PHPickerResult` array selected by the user.
    func pickResults(completion: @escaping ([PHPickerResult]) -> Void)
}

public final class MEGAPhotoPicker: MEGAPhotoPickerProtocol {
    private var photoPickerDelegate: PhotoPickerDelegate?
    private weak var presenter: UIViewController?
    
    public init(presenter: UIViewController) {
        self.presenter = presenter
    }
    
    public func pickAssets(completion: @escaping ([PHAsset], Int) -> Void) {
        let picker = makePicker()
        let delegate = PhotoPickerDelegate { [weak self] assets, selectedCount in
            self?.photoPickerDelegate = nil
            completion(assets, selectedCount)
        }
        self.photoPickerDelegate = delegate
        picker.delegate = delegate
        picker.presentationController?.delegate = delegate

        presenter?.present(picker, animated: true)
    }

    public func pickResults(completion: @escaping ([PHPickerResult]) -> Void) {
        // Capped to 400 at a time to mitigate bulk pick hanging.
        // .current to avoid transcoding if possible.
        let picker = makePicker(selectionLimit: 400, mode: .current)
        let delegate = PhotoPickerDelegate(completion: nil) { [weak self] results in
            self?.photoPickerDelegate = nil
            completion(results)
        }
        self.photoPickerDelegate = delegate
        picker.delegate = delegate
        picker.presentationController?.delegate = delegate

        presenter?.present(picker, animated: true)
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

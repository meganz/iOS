import PhotosUI

final class PhotoPickerDelegate: PHPickerViewControllerDelegate {
    private let completion: ([PHAsset]) -> Void
    private var hasFinishedPicking = false
    
    init(completion: @escaping ([PHAsset]) -> Void) {
        self.completion = completion
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !hasFinishedPicking else { return }
        hasFinishedPicking = true
        let assets = results.toPHAssets()
        completion(assets)
        picker.dismiss(animated: true)
    }
}

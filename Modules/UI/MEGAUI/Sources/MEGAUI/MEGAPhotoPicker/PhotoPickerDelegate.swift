import PhotosUI

final class PhotoPickerDelegate: PHPickerViewControllerDelegate {
    private let completion: ([PHAsset], Int) -> Void
    private var hasFinishedPicking = false
    
    init(completion: @escaping ([PHAsset], Int) -> Void) {
        self.completion = completion
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !hasFinishedPicking else { return }
        hasFinishedPicking = true
        let assets = results.toPHAssets()
        completion(assets, results.count)
        picker.dismiss(animated: true)
    }
}

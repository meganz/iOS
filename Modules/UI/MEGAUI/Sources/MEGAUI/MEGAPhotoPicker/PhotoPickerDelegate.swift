import PhotosUI

final class PhotoPickerDelegate: PHPickerViewControllerDelegate {
    private let completion: ([PHAsset]) -> Void
    
    init(completion: @escaping ([PHAsset]) -> Void) {
        self.completion = completion
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {        
        let assets = results.toPHAssets()
        completion(assets)
        picker.dismiss(animated: true)
    }
}

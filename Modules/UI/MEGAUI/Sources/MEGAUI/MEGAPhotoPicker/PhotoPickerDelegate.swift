import PhotosUI

final class PhotoPickerDelegate: NSObject, PHPickerViewControllerDelegate {
    private let completion: (([PHAsset], Int) -> Void)?
    private let completionResult: (([PHPickerResult]) -> Void)?
    private var hasFinishedPicking = false
    
    init(
        completion: (([PHAsset], Int) -> Void)? = nil,
        completionResult: (([PHPickerResult]) -> Void)? = nil
    ) {
        self.completion = completion
        self.completionResult = completionResult
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !hasFinishedPicking else { return }
        hasFinishedPicking = true
        picker.dismiss(animated: true) { [self] in
            if let completion {
                let assets = results.toPHAssets()
                completion(assets, results.count)
            }
            completionResult?(results)
        }
    }
}

extension PhotoPickerDelegate: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard !hasFinishedPicking else { return }
        hasFinishedPicking = true
        completion?([], 0)
        completionResult?([])
    }
}

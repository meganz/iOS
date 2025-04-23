import Combine
import UIKit

final class LegacySlideShowCollectionViewCell: UICollectionViewCell {

    let imageScrollView = ImageScrollView()

    private weak var slideshowInteraction: (any SlideShowInteraction)?
    private var viewModelSubject = PassthroughSubject<SlideShowCellViewModel, Never>()
    private var cancellables = Set<AnyCancellable>()

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        addSubview(imageScrollView)
        imageScrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageScrollView.topAnchor.constraint(equalTo: self.topAnchor),
            imageScrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageScrollView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            imageScrollView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])

        imageScrollView.imageContentMode = .aspectFit
        imageScrollView.initialOffset = .center

        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGestureRecognizer(_:)))
        addGestureRecognizer(singleTapGesture)

        bindToViewModel()
    }

    func update(with viewModel: SlideShowCellViewModel, andInteraction slideshowInteraction: some SlideShowInteraction) {
        self.slideshowInteraction = slideshowInteraction
        imageScrollView.setup()
        viewModelSubject.send(viewModel)
    }

    private func bindToViewModel() {

        viewModelSubject
            .map { viewModel -> AnyPublisher<SlideShowCellViewModel.ImageSource?, Never> in
                viewModel.$imageSource.eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] imageSource in
                guard
                    let self,
                    let imageSource else { return }

                imageScrollView.display(
                    image: imageSource.image,
                    gifImageFileUrl: imageSource.fileUrl)
            }
            .store(in: &cancellables)
    }

    func resetZoomScale() {
        imageScrollView.resetZoomScale()
    }

    @objc func singleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        slideshowInteraction?.pausePlaying()
    }
}

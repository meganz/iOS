
struct EmptyStateViewModel {
    let image: UIImage
    let title: String
}

extension EmptyStateView {
    convenience init(emptyStateViewModel: EmptyStateViewModel) {
        self.init(image: emptyStateViewModel.image,
                  title: emptyStateViewModel.title,
                  description: nil,
                  buttonTitle: nil)
    }
}

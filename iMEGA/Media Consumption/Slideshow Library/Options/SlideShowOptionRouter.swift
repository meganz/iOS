import SwiftUI

@available(iOS 14.0, *)
final class SlideShowOptionRouter: Routing {
    private weak var presenter: UIViewController?
    
    init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let viewModel = SlideShowOptionViewModel(cellViewModels: makeCells())
        return UIHostingController(rootView: SlideShowOptionView(viewModel: viewModel, router: SlideShowOptionContentRouter()))
    }
    
    func start() {
        let vc = build()
        presenter?.present(vc, animated: true)
    }
}

@available(iOS 14.0, *)
extension SlideShowOptionRouter {
    @SlideShowOptionBuilder
    private func makeCells() -> [SlideShowOptionCellViewModel] {
        SlideShowOptionCellViewModel(title: Strings.Localizable.Slideshow.PreferenceSetting.speed, type: .detail, children: makeChildrenForSlideShowSpeed())
        SlideShowOptionCellViewModel(title: Strings.Localizable.Slideshow.PreferenceSetting.order, type: .detail, children: makeChildrenForSlideShowOrder())
        SlideShowOptionCellViewModel(title: Strings.Localizable.Slideshow.PreferenceSetting.SlideshowOptions.repeat, type: .toggle, children: [])
        SlideShowOptionCellViewModel(title: "", type: .none, children: [])
        SlideShowOptionCellViewModel(title: Strings.Localizable.Slideshow.PreferenceSetting.SlideshowOptions.subFolders, type: .toggle, children: [])
    }
    
    @SlideShowOptionChildrenBuilder
    private func makeChildrenForSlideShowSpeed() -> [SlideShowOptionDetailCellViewModel] {
        SlideShowOptionDetailCellViewModel(title: Strings.Localizable.Slideshow.PreferenceSetting.Speed.slow, isSelcted: false)
        SlideShowOptionDetailCellViewModel(title: Strings.Localizable.Slideshow.PreferenceSetting.Speed.normal, isSelcted: true)
        SlideShowOptionDetailCellViewModel(title: Strings.Localizable.Slideshow.PreferenceSetting.Speed.fast, isSelcted: false)
    }
    
    @SlideShowOptionChildrenBuilder
    private func makeChildrenForSlideShowOrder() -> [SlideShowOptionDetailCellViewModel] {
        SlideShowOptionDetailCellViewModel(image: Asset.Images.AudioPlayer.shuffleAudio, title: Strings.Localizable.Slideshow.PreferenceSetting.Order.shuffle, isSelcted: true)
        SlideShowOptionDetailCellViewModel(image: Asset.Images.ActionSheetIcons.SortBy.newest, title: Strings.Localizable.newest, isSelcted: false)
        SlideShowOptionDetailCellViewModel(image: Asset.Images.ActionSheetIcons.SortBy.oldest, title: Strings.Localizable.oldest, isSelcted: false)
    }
}

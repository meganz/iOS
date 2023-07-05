extension InterfaceStyle {

    var pageControlStyleFactory: some PageControlStyleFactory {
        PageControlStyleFactoryImpl(
            colorFactory: colorFactory
        )
    }
}

typealias PageControlStyler = (UIPageControl) -> Void

enum MEGAPageControlStyle {

    case homeBanner
}

protocol PageControlStyleFactory {

    func styler(of style: MEGAPageControlStyle) -> PageControlStyler
}

private struct PageControlStyleFactoryImpl: PageControlStyleFactory {

    let colorFactory: any ColorFactory

    func styler(of style: MEGAPageControlStyle) -> PageControlStyler {
        switch style {
        case .homeBanner:
            return { pageControl in
                colorFactory.tintColor(.secondary).asTintColorStyle.applied(
                    on: colorFactory.tintColor(.primary).asSelectedTintColorStyle.applied(
                        on: pageControl
                    )
                )
            }
        }
    }
}

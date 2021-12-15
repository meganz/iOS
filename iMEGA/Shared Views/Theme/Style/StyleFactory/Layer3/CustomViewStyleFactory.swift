import Foundation

extension InterfaceStyle {

    var customViewStyleFactory: CustomViewStyleFactory {
        return CustomViewStyleFactoryImpl(borderStyleFactory: borderStyleFactory,
                                          backgroundStyleFactory: backgroundStyleFactory,
                                          cornerStyleFactory: cornerStyleFactory)
    }
}

typealias ViewStyler = (UIView) -> Void

enum MEGACustomViewStyle {
    case warning

    // MARK: - Home Screen
    case searchController
    case slideIndicatorContainerView
    case slideIndicator
    case homeBannerView
    case homeCarouselCollectionView
    case homeCarouselPageControl
}

protocol CustomViewStyleFactory {

    func styler(of style: MEGACustomViewStyle) -> ViewStyler
}

private struct CustomViewStyleFactoryImpl: CustomViewStyleFactory {

    let borderStyleFactory: BorderStyleFactory

    let backgroundStyleFactory: BackgroundStyleFactory

    let cornerStyleFactory: CornerStyleFactory

    func styler(of style: MEGACustomViewStyle) -> ViewStyler {
        let borderStyleFactory = self.borderStyleFactory
        let backgroundStyleFactory = self.backgroundStyleFactory
        let cornerStyleFactory = self.cornerStyleFactory
        switch style {
        case .warning:
            return { view in
                backgroundStyleFactory.backgroundStyle(of: .warning)
                    .applied(on: cornerStyleFactory.cornerStyle(of: .round)
                        .applied(on: borderStyleFactory.borderStyle(of: .warning)
                            .applied(on: view)))
            }
        case .searchController:
            return { view in
                backgroundStyleFactory.backgroundStyle(of: .homeTopSide).applied(on: view)
            }
        case .slideIndicatorContainerView:
            return { view in
                backgroundStyleFactory.backgroundStyle(of: .slideIndicatorContainerView).applied(on: view)
            }
        case .slideIndicator:
            return { view in
                backgroundStyleFactory.backgroundStyle(of: .slideIndicator)
                    .applied(on: cornerStyleFactory.cornerStyle(of: .twoAndHalf)
                        .applied(on: view))
            }
        case .homeBannerView:
            return { view in
                backgroundStyleFactory.backgroundStyle(of: .homeTopSide).applied(on: view)
            }
        case .homeCarouselCollectionView:
            return { view in
                backgroundStyleFactory.backgroundStyle(of: .homeTopSide).applied(on: view)
            }
        case .homeCarouselPageControl:
            fatalError()
        }
    }
}

import MEGADesignToken
import SwiftUI

extension Array where Element == ResultProperty {
    
    func propertiesFor(
        mode: ResultCellLayout,
        placement: PropertyPlacement
    ) -> [ResultProperty] {
        filter { resultProperty in
            // here we check, for a given display mode, where given property wants to be placed
            // and if it matches the filtered for value, we return it
            resultProperty.placement(mode) == placement
        }
        .sorted()
    }
    
    @MainActor @ViewBuilder func propertyViewsFor(
        layout: ResultCellLayout,
        placement: PropertyPlacement, 
        colorAssets: SearchConfig.ColorAssets
    ) -> some View {
        Group {
            ForEach(propertiesFor(mode: layout, placement: placement)) { resultProperty in
                propertyView(for: resultProperty, colorAssets: colorAssets, placement: placement)
                    .padding(.horizontal, layout == .thumbnail ? TokenSpacing._2 : 0)
                    .accessibilityLabel(resultProperty.accessibilityLabel)
            }
        }
    }
    
    @MainActor @ViewBuilder func propertyView(for property: ResultProperty, colorAssets: SearchConfig.ColorAssets, placement: PropertyPlacement) -> some View {
        switch property.content {
        case let .icon(image: image, layoutConfig: layoutConfig):
            property.resultPropertyImage(image: image, layoutConfig: layoutConfig, colorAssets: colorAssets, placement: placement)
                .frame(width: layoutConfig.size, height: layoutConfig.size)
                .padding(.horizontal, layoutConfig.horizontalPadding)
        case .text(let text):
            Text(text)
        case .spacer:
            Spacer()
        }
    }
}

extension ResultProperty {
    @ViewBuilder
    func resultPropertyImage(image: UIImage, layoutConfig: ResultProperty.Content.LayoutConfiguration, colorAssets: SearchConfig.ColorAssets, placement: PropertyPlacement) -> some View {
        if layoutConfig.scalable {
            Image(uiImage: image)
                .resizable()
                .renderingMode(layoutConfig.renderingMode)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(vibrancyEnabled ? colorAssets.vibrantColor : colorAssets.resultPropertyColor)
        } else {
            Image(uiImage: image)
        }
    }
}

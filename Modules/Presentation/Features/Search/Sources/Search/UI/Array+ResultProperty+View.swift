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
    
    @ViewBuilder func propertyViewsFor(
        layout: ResultCellLayout,
        placement: PropertyPlacement, 
        colorAssets: SearchConfig.ColorAssets
    ) -> some View {
        Group {
            ForEach(propertiesFor(mode: layout, placement: placement)) { resultProperty in
                propertyView(for: resultProperty, colorAssets: colorAssets, placement: placement)
                    .accessibilityLabel(resultProperty.accessibilityLabel)
            }
        }
    }
    
    @ViewBuilder func propertyView(for property: ResultProperty, colorAssets: SearchConfig.ColorAssets, placement: PropertyPlacement) -> some View {
        switch property.content {
        case let .icon(image: image, scalable: scalable):
            property.resultPropertyImage(image: image, scalable: scalable, colorAssets: colorAssets, placement: placement)
                .frame(width: 12, height: 12)

        case .text(let text):
            Text(text)
        case .spacer:
            Spacer()
        }
    }
    
}

extension ResultProperty {
    @ViewBuilder
    func resultPropertyImage(image: UIImage, scalable: Bool, colorAssets: SearchConfig.ColorAssets, placement: PropertyPlacement) -> some View {
        if scalable {
            Image(uiImage: image)
                .renderingMode(.template)
                .resizable()
                .foregroundStyle(vibrancyEnabled ? colorAssets.vibrantColor : colorAssets.resultPropertyColor)
                .scaledToFit()
        } else {
            Image(uiImage: image)
        }
    }
}

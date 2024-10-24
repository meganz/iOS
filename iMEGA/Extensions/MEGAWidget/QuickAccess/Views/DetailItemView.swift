import MEGASwiftUI
import SwiftUI

struct DetailItemView: View {
    let item: QuickAccessItemModel
    
    var body: some View {
        HStack {
            item.thumbnail
                .resizable()
                .applyAccentedDesaturatedRenderingMode()
                .frame(width: 24, height: 24, alignment: .leading)
                .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 0))
            
            if let image = item.image, let description = item.description {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.system(size: 12, weight: .medium, design: .default))
                        .foregroundColor(Color(UIColor.label))
                        .padding([.top], 10)
                        .lineLimit(1)
                    HStack(spacing: 3) {
                        image
                            .frame(width: 12, height: 12, alignment: .leading)
                            .padding(0)
                        Text(description)
                            .font(.system(size: 10, weight: .regular, design: .default))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .padding(0)
                        Spacer()
                    }
                    .padding([.bottom], 10)
                    
                }
            } else {
                Text(item.name)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .foregroundColor(Color(UIColor.label))
                    .padding([.bottom, .top], 8)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, idealHeight: 50)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color("Separator"), lineWidth: 1)
        )
        .padding(8)
    }
}

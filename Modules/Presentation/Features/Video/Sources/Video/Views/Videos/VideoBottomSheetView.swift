import MEGADesignToken
import SwiftUI

struct SingleSelectionBottomSheetView: View {
    let videoConfig: VideoConfig
    let title: String
    let options: [String]
    @Binding var selectedOption: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.body)
                .bold()
                .foregroundStyle(videoConfig.colorAssets.primaryTextColor)
                .padding(.top, 24)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity)
                .background(videoConfig.colorAssets.bottomSheetHeaderBackgroundColor)
            
            List(options, id: \.self) { title in
                rowCell(title: title)
                    .listRowSeparatorTint(TokenColors.Border.strong.swiftUI)
                    .listRowBackground(videoConfig.colorAssets.bottomSheetCellSelectedBackgroundColor)
                    .frame(height: 50)
                    .onTapGesture {
                        selectedOption = title
                    }
            }
            .listStyle(PlainListStyle())
        }
        .background(videoConfig.colorAssets.bottomSheetBackgroundColor)
        .ignoresSafeArea()
    }
    
    private func rowCell(title: String) -> some View {
        HStack {
            cellTitle(title: title)
                .frame(maxWidth: .infinity, alignment: .leading)
            if selectedOption == title {
                Image(uiImage: videoConfig.videoListAssets.checkmarkImage)
                    .foregroundStyle(videoConfig.colorAssets.checkmarkColor)
            }
        }
        .contentShape(Rectangle())
    }
    
    private func cellTitle(title: String) -> some View {
        Text(title)
            .font(.system(size: 16))
            .foregroundStyle(videoConfig.colorAssets.primaryTextColor)
    }
}

#Preview {
    SingleSelectionBottomSheetView(
        videoConfig: .preview,
        title: "Location",
        options: ["Option 1", "Option 2", "Option 3"], 
        selectedOption: .constant("")
    )
    .padding(.top, 4)
}

#Preview {
    SingleSelectionBottomSheetView(
        videoConfig: .preview,
        title: "Location",
        options: ["Option 1", "Option 2", "Option 3"],
        selectedOption: .constant("")
    )
    .padding(.top, 4)
    .preferredColorScheme(.dark)
}

import SwiftUI

struct SearchResultThumbnailItemView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @ObservedObject var viewModel: SearchResultRowViewModel

    var body: some View {
        content
            .taskForiOS14 {
                await viewModel.loadThumbnail()
                await viewModel.loadProperties()
            }
            .contextMenuWithPreview(
                actions: viewModel.previewContent.actions.toUIActions,
                sourcePreview: {
                    content
                },
                contentPreviewProvider: {
                    switch viewModel.previewContent.previewMode {
                    case let .preview(contentPreviewProvider):
                        return contentPreviewProvider()
                    case .noPreview:
                        return nil
                    }
                },
                didTapPreview: viewModel.actions.previewTapAction,
                didSelect: viewModel.actions.selectionAction
            )
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.thumbnailInfo.displayMode == .file {
            FileView(viewModel: viewModel)
        } else {
            FolderView(viewModel: viewModel)
        }
    }
}

private final class FileViewModel: ObservableObject {
    @Published var properties: [UIImage] = []

    init(properties: [UIImage]) {
        self.properties = properties
    }
}

private struct FileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @ObservedObject var viewModel: SearchResultRowViewModel

    var body: some View {
        VStack(spacing: .zero) {
            topInfoView
            bottomInfoView
        }
        .frame(height: 214)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipped()
    }

    private var topInfoView: some View {
        ZStack {
            background

            VStack(spacing: .zero) {
                topNodeIconsView

                if !(viewModel.thumbnailInfo.hasThumbnail) {
                    thumbnailIconView
                } else {
                    Spacer()
                }
            }
            .overlay(videoPlayerItems, alignment: .bottomLeading)
        }
    }

    @ViewBuilder
    private var background: some View {
        if viewModel.thumbnailInfo.hasThumbnail {
            Image(uiImage: viewModel.thumbnailImage)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .frame(height: 174)
                .clipped()
                .background(thumbnailBackgroundColor)
        } else {
            thumbnailBackgroundColor
        }
    }

    private var topNodeIconsView: some View {
        HStack {
            Spacer()

            HStack(spacing: 4) {
                ForEach(viewModel.properties, id: \.self) {
                    topNodeIcon(with: $0)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(height: 24)
        .padding(.trailing, 5)
        .background(
            viewModel.properties.isNotEmpty ? topNodeIconsBackgroundColor : .clear
        )
    }

    private func topNodeIcon(with uiImage: UIImage) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
    }

    @ViewBuilder
    private var thumbnailIconView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image(uiImage: viewModel.thumbnailImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                Spacer()
            }
            Spacer()
        }
    }

    private var videoPlayerItems: some View {
        HStack(spacing: 1) {
            if !(viewModel.thumbnailInfo.isVideoIconHidden) {
                Image(uiImage: viewModel.playImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }

            if let duration = viewModel.thumbnailInfo.duration {
                Text(duration)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.9))
                    .background(viewModel.colorAssets._161616.opacity(0.5))
                    .cornerRadius(4)
            }

            Spacer()
        }
        .padding(.leading, 3)
        .padding(.trailing, 8)
        .frame(height: 16)
    }

    private var bottomInfoView: some View {
        HStack(spacing: .zero) {
            VStack(alignment: .leading, spacing: .zero) {
                HStack(spacing: 4) {
                    Text(viewModel.thumbnailInfo.title)
                        .foregroundColor(viewModel.thumbnailInfo.takedownImage != nil ? takeDownTextColor : .primary)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)

                    if let takeDownImage = viewModel.thumbnailInfo.takedownImage {
                        Image(uiImage: takeDownImage)
                    }

                    if let path = viewModel.thumbnailInfo.iconIndicatorPath {
                        Image(path)
                            .frame(width: 12)
                    }
                }

                HStack(spacing: 4) {
                    Text(viewModel.thumbnailInfo.subtitle)
                        .foregroundColor(.primary)
                        .font(.caption)

                    if !(viewModel.isDownloadHidden) {
                        Image(uiImage: viewModel.downloadedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                    }
                }
            }

            Spacer()
            moreButton
        }
        .padding(.horizontal, 8)
    }

    private var moreButton: some View {
        UIButtonWrapper(
            image: viewModel.moreGrid
        ) { button in
            viewModel.actions.contextAction(button)
        }
        .frame(width: 40, height: 40)
    }

    private var borderColor: Color {
        colorScheme == .light ? viewModel.colorAssets.F7F7F7 : viewModel.colorAssets._545458
    }

    private var takeDownTextColor: Color {
        if colorScheme == .light {
            if colorSchemeContrast == .increased {
                return viewModel.colorAssets.CE0A11
            } else {
                return viewModel.colorAssets.F30C14
            }
        } else {
            if colorSchemeContrast == .increased {
                return viewModel.colorAssets.F95C61
            } else {
                return viewModel.colorAssets.F7363D
            }
        }
    }

    private var topNodeIconsBackgroundColor: Color {
        colorScheme == .light ? Color(white: 1, opacity: 0.3)
        : Color(white: 0, opacity: 0.4)
    }

    private var thumbnailBackgroundColor: Color {
        colorScheme == .light ? viewModel.colorAssets.F7F7F7 : viewModel.colorAssets._1C1C1E
    }
}

private struct FolderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    @ObservedObject var viewModel: SearchResultRowViewModel

    var body: some View {
        HStack(spacing: .zero) {
            HStack(spacing: 8) {
                thumbnailImage

                VStack(alignment: .leading, spacing: .zero) {
                    titleAndLabel
                    infoAndIcons
                }
                .padding(.vertical, 8)
            }
            Spacer()
            moreButton
        }
        .padding(.leading, 9)
        .padding(.trailing, 8)
        .frame(height: 46)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    private var thumbnailImage: some View {
        Image(uiImage: viewModel.thumbnailImage)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
    }

    private var titleAndLabel: some View {
        HStack(spacing: 4) {
            Text(viewModel.thumbnailInfo.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(viewModel.thumbnailInfo.takedownImage != nil ? takeDownTextColor : .primary)

            if let takeDownImage = viewModel.thumbnailInfo.takedownImage {
                Image(uiImage: takeDownImage)
            }

            if let path = viewModel.thumbnailInfo.iconIndicatorPath {
                Image(path)
                    .frame(width: 12)
            }
        }
        .frame(height: 12)
    }

    private var infoAndIcons: some View {
        HStack(spacing: 4) {
            Text(viewModel.thumbnailInfo.subtitle)
                .font(.caption)
                .foregroundColor(.primary)

            ForEach(viewModel.properties, id: \.self) {
                icon(with: $0)
            }
        }
    }

    private func icon(with image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
    }

    private var moreButton: some View {
        UIButtonWrapper(
            image: viewModel.moreList
        ) { button in
            viewModel.actions.contextAction(button)
        }
        .frame(width: 24, height: 24)
    }

    private var borderColor: Color {
        colorScheme == .light ? viewModel.colorAssets.F7F7F7 : viewModel.colorAssets._545458
    }

    private var takeDownTextColor: Color {
        if colorScheme == .light {
            if colorSchemeContrast == .increased {
                return viewModel.colorAssets.CE0A11
            } else {
                return viewModel.colorAssets.F30C14
            }
        } else {
            if colorSchemeContrast == .increased {
                return viewModel.colorAssets.F95C61
            } else {
                return viewModel.colorAssets.F7363D
            }
        }
    }
}

struct SearchResultThumbnailItemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            file
            folder
        }
        .previewLayout(.sizeThatFits)
    }

    private static var folder: some View {
        SearchResultThumbnailItemView(
            viewModel: .init(
                with: .init(
                    id: .zero,
                    title: "title_2",
                    description: "subtitle_2",
                    properties: [],
                    thumbnailImageData: { UIImage(systemName: "scribble")?.pngData() ?? Data() },
                    type: .node,
                    thumbnailPreviewInfo: .init(
                        id: "1",
                        displayMode: .folder,
                        title: "Folder Title",
                        subtitle: "Info",
                        iconIndicatorPath: nil,
                        duration: "2:00",
                        isVideoIconHidden: true,
                        hasThumbnail: true,
                        thumbnailImageData: { .init() },
                        propertiesData: { [] },
                        downloadVisibilityData: { false }
                    )
                ),
                rowAssets: .init(
                    contextImage: UIImage(systemName: "ellipsis")!,
                    itemSelected: UIImage(systemName: "ellipsis")!,
                    itemUnselected: UIImage(systemName: "ellipsis")!,
                    playImage: UIImage(systemName: "ellipsis")!,
                    downloadedImage: UIImage(systemName: "ellipsis")!,
                    moreList: UIImage(systemName: "ellipsis")!,
                    moreGrid: UIImage(systemName: "ellipsis")!
                ),
                colorAssets: .init(
                    F7F7F7: Color("F7F7F7"),
                    _161616: Color("161616"),
                    _545458: Color("545458"),
                    CE0A11: Color("CE0A11"),
                    F30C14: Color("F30C14"),
                    F95C61: Color("F95C61"),
                    F7363D: Color("F7363D"),
                    _1C1C1E: Color("1C1C1E")
                ),
                previewContent: .init(
                    actions: [.init(title: "Select", imageName: "checkmark.circle", handler: { })],
                    previewMode: .preview({
                        UIHostingController(rootView: Text("Hello world"))
                    })
                ),
                actions: .init(
                    contextAction: { _ in },
                    selectionAction: {},
                    previewTapAction: {}
                )
            )
        )
        .frame(width: 173, height: 214)
    }

    private static var file: some View {
        SearchResultThumbnailItemView(
            viewModel: .init(
                with: .init(
                    id: .zero,
                    title: "title_1",
                    description: "subtitle_1",
                    properties: [],
                    thumbnailImageData: { UIImage(systemName: "scribble")?.pngData() ?? Data() },
                    type: .node,
                    thumbnailPreviewInfo: .init(
                        id: "1",
                        displayMode: .file,
                        title: "File title",
                        subtitle: "Info",
                        iconIndicatorPath: nil,
                        duration: "2:00",
                        isVideoIconHidden: true,
                        hasThumbnail: true,
                        thumbnailImageData: { .init() },
                        propertiesData: { [] },
                        downloadVisibilityData: { false }
                    )
                ),
                rowAssets: .init(
                    contextImage: UIImage(systemName: "ellipsis")!,
                    itemSelected: UIImage(systemName: "ellipsis")!,
                    itemUnselected: UIImage(systemName: "ellipsis")!,
                    playImage: UIImage(systemName: "ellipsis")!,
                    downloadedImage: UIImage(systemName: "ellipsis")!,
                    moreList: UIImage(systemName: "ellipsis")!,
                    moreGrid: UIImage(systemName: "ellipsis")!
                ),
                colorAssets: .init(
                    F7F7F7: Color("F7F7F7"),
                    _161616: Color("161616"),
                    _545458: Color("545458"),
                    CE0A11: Color("CE0A11"),
                    F30C14: Color("F30C14"),
                    F95C61: Color("F95C61"),
                    F7363D: Color("F7363D"),
                    _1C1C1E: Color("1C1C1E")
                ),
                previewContent: .init(
                    actions: [.init(title: "Select", imageName: "checkmark.circle", handler: { })],
                    previewMode: .preview({
                        UIHostingController(rootView: Text("Hello world"))
                    })
                ),
                actions: .init(
                    contextAction: { _ in },
                    selectionAction: {},
                    previewTapAction: {}
                )
            )
        )
        .frame(width: 173, height: 46)
    }
}

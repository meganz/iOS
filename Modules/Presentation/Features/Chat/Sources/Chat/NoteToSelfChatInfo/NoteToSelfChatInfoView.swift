import MEGAAssets
import MEGAL10n
import MEGASwiftUI
import SwiftUI

public struct NoteToSelfChatInfoView: View {
    @StateObject private var viewModel: NoteToSelfChatInfoViewModel
    
    public init(viewModel: @autoclosure @escaping () -> NoteToSelfChatInfoViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    
    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                noteToSelfHeaderView
                sharedFilesView
                manageChatHistoryView
                archiveChatView
            }
        }
        .background()
        .navigationTitle(Strings.Localizable.info)
        .alert(viewModel.archiveChatAlertTitle, isPresented: $viewModel.showArchiveChatAlert) {
            Button {
                viewModel.cancelArchiveChat()
            } label: {
                Text(Strings.Localizable.cancel)
            }
            Button {
                Task { await viewModel.archiveChat() }
            } label: {
                Text(Strings.Localizable.ok)
            }
        }
    }
    
    private var noteToSelfHeaderView: some View {
        VStack {
            Divider()
            HStack {
                noteToSelfImage
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(8)
                
                VStack(alignment: .leading) {
                    Text(Strings.Localizable.Chat.Messages.NoteToSelf.title)
                        .font(.subheadline)
                }
                Spacer()
            }
            .padding(.horizontal)
            Divider()
        }
    }
    
    private var noteToSelfImage: Image {
        if viewModel.isNoteToSelfChatAndEmpty {
            MEGAAssets.Image.noteToSelfSmall
        } else {
            MEGAAssets.Image.noteToSelfBlue
        }
    }
    
    private var sharedFilesView: some View {
        DisclosureView(
            image: MEGAAssets.Image.sharedFiles,
            text: Strings.Localizable.sharedFiles) {
                viewModel.filesRowTapped()
            }
    }
    
    private var manageChatHistoryView: some View {
        DisclosureView(
            image: MEGAAssets.Image.clearChatHistory,
            text: Strings.Localizable.manageChatHistory) {
                viewModel.manageChatHistoryTapped()
            }
    }
    
    private var archiveChatView: some View {
        VStack {
            Divider()
            HStack {
                archiveChatImage
                Text(viewModel.isArchived ? Strings.Localizable.unarchiveChat : Strings.Localizable.archiveChat)
                    .font(.body)
                Spacer()
            }
            .padding(.horizontal)
            Divider()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.archiveChatTapped()
        }
    }
    
    private var archiveChatImage: Image {
        if viewModel.isArchived {
            MEGAAssets.Image.unArchiveChat
        } else {
            MEGAAssets.Image.archiveChat
        }
    }
}

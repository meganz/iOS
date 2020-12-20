
import WidgetKit
import SwiftUI

struct ShortcutsProvider: IntentTimelineProvider {

    typealias Intent = SelectShortcutIntent

    typealias Entry = ShortcutsWidgetEntry

    func placeholder(in context: Context) -> Entry {
        return Entry(date: Date(), shortcuts: ShortcutDetail.availableShortcuts)
    }
    
    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: Date(), shortcuts: ShortcutDetail.availableShortcuts))
    }
    
    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let timeline = Timeline(entries: [Entry(date: Date(), shortcuts: shortcuts(for: configuration))], policy: .never)
        completion(timeline)
    }
    
    func shortcuts(for configuration: Intent) -> [ShortcutDetail] {
        var shortcuts = [ShortcutDetail]()
        configuration.shortcut?.forEach({ (intentShortcut) in
            shortcuts.append(shortcut(for: intentShortcut))
        })
        return shortcuts
    }
    
    func shortcut(for intent: IntentShortcut?) -> ShortcutDetail {
        
        guard let identifier = intent?.identifier else {
            return .defaultShortcut
        }
        
        switch identifier {
        case ShortcutDetail.uploadFile.link:
            return .uploadFile
        case ShortcutDetail.scanDocument.link:
            return.scanDocument
        case ShortcutDetail.startConversation.link:
            return .startConversation
        case ShortcutDetail.addContact.link:
            return .addContact
        default:
            return .defaultShortcut
        }
    }
}

struct ShortcutsWidget: Widget {
    let kind: String = "MEGAShortcutsWidget"

    var body: some WidgetConfiguration {
        
        IntentConfiguration(kind: kind, intent: SelectShortcutIntent.self, provider: ShortcutsProvider()) { entry in
            ShortcutsWidgetView(entry: entry)
        }
        .configurationDisplayName(NSLocalizedString("Shortcuts", comment: "Text title for shortcuts, ie in the widget"))
        .description(NSLocalizedString("Launch the MEGA app to perform an action", comment: "Text description leading the user to perform an action, ie the shortcuts widget"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ShortcutsWidgetEntry: TimelineEntry {
    let date: Date
    let shortcuts: [ShortcutDetail]
}

struct SmallShortcutWidgetView: View {
    let shortcut: ShortcutDetail
    
    var body: some View {
        
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Image(shortcut.imageName)
                    .frame(width: 56, height: 56, alignment: .leading)
                Spacer()
                Text(shortcut.title)
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(.white)
            }
            .padding(16)
            Spacer()
        }
        .background(LinearGradient(gradient: Gradient(colors: [shortcut.topBackgroundColor, shortcut.bottomBackgroundColor]), startPoint: .top, endPoint: .bottom))
        .widgetURL(URL(string: shortcut.link))
    }
}

struct ShortcutView: View {
    let shortcut: ShortcutDetail
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Image(shortcut.imageName)
                    .resizable()
                    .frame(width: 28, height: 28, alignment: .leading)
                    .padding([.leading, .top, .trailing], 8)
                Text(shortcut.title)
                    .font(.system(size: 12, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .padding([.leading, .bottom, .trailing], 8)
            }
            .frame(maxHeight: .infinity)
            Spacer()
        }
        .background(LinearGradient(gradient: Gradient(colors: [shortcut.topBackgroundColor, shortcut.bottomBackgroundColor]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(8)
    }
}

struct MediumShortcutsWidgetView: View {
    let shortcuts: [ShortcutDetail]
    
    var body: some View {
        
        VStack {
            HStack(alignment: .top, spacing: 8) {
                if let firstShortcut = shortcuts[0] {
                    Link(destination: URL(string: firstShortcut.link)!, label: {
                        ShortcutView(shortcut: firstShortcut)
                    })
                }
                if let secondShortcut = shortcuts[1] {
                    Link(destination: URL(string: secondShortcut.link)!, label: {
                        ShortcutView(shortcut: secondShortcut)
                    })
                }
            }
            
            HStack(alignment: .top, spacing: 8) {
                if let thirdShortcut = shortcuts[2] {
                    Link(destination: URL(string: thirdShortcut.link)!, label: {
                        ShortcutView(shortcut: thirdShortcut)
                    })
                }
                if let fourthShortcut = shortcuts[3] {
                    Link(destination: URL(string: fourthShortcut.link)!, label: {
                        ShortcutView(shortcut: fourthShortcut)
                    })
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("SecondaryBackground"))
    }
}

struct ShortcutsWidgetView: View {
    var entry: ShortcutsProvider.Entry
    
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallShortcutWidgetView(shortcut: entry.shortcuts.first ?? ShortcutDetail.defaultShortcut)
        case .systemMedium:
            MediumShortcutsWidgetView(shortcuts: entry.shortcuts)
        default:
            EmptyView()
        }
    }
}

struct ShortcutsWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        ShortcutsWidgetView(entry: ShortcutsWidgetEntry(date: Date(), shortcuts: ShortcutDetail.availableShortcuts))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        ShortcutsWidgetView(entry: ShortcutsWidgetEntry(date: Date(), shortcuts: ShortcutDetail.availableShortcuts))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

import MEGADomain
import SwiftUI

struct ContextMenuWithButtonView<Label>: View where Label: View {
    let menu: CMEntity
    let label: () -> Label
    let actionHandler: (String, CMElementTypeEntity) -> Void

    init(
        menu: CMEntity,
        @ViewBuilder label: @escaping () -> Label,
        actionHandler: @escaping (String, CMElementTypeEntity) -> Void
    ) {
        self.menu = menu
        self.label = label
        self.actionHandler = actionHandler
    }

    var body: some View {
        Menu(content: {
            ContextMenuView(menu: menu, actionHandler: actionHandler)
        }, label: label)
    }
}

private struct ContextMenuView: View {
    let menu: CMEntity
    let actionHandler: (String, CMElementTypeEntity) -> Void

    var body: some View {
        var menuModel = menu.toContextMenuModel()
        if let data = menuModel.data {
            convertToSwiftUIMenu(menu: menu, menuModel: menuModel, data: data)
        } else {
            ContextMenuListView(items: menu.children, actionHandler: actionHandler)
        }
    }

    @ViewBuilder
    private func convertToSwiftUIMenu(
        menu: CMEntity, menuModel: ContextMenuModel, data: ContextMenuDataModel
    ) -> some View {
        Section {
            Menu {
                ContextMenuListView(items: menu.children, actionHandler: actionHandler)
            } label: {
                ContextMenuDataModelView(model: data)
            }
        }
    }
}

private struct ContextMenuListView: View {
    let items: [CMElement]
    let actionHandler: (String, CMElementTypeEntity) -> Void
    private var onlyContainsActionItems: Bool { items.allSatisfy { $0 is CMActionEntity } }

    var body: some View {
        if onlyContainsActionItems {
            ContextMenuActionsPicker(items: items.compactMap { $0 as? CMActionEntity }, actionHandler: actionHandler)
        } else {
            sectionView()
        }
    }

    @ViewBuilder
    private func sectionView() -> some View {
        Section {
            ForEach(0..<items.count, id: \.self) { index in
                itemView(for: items[index])
            }
        }
    }

    @ViewBuilder
    private func itemView(for item: CMElement) -> some View {
        if let menu = item as? CMEntity {
            ContextMenuView(menu: menu, actionHandler: actionHandler)
        } else if let action = item as? CMActionEntity {
            ContextMenuActionItemView(item: action, actionHandler: actionHandler)
        } else {
            EmptyView()
        }
    }
}

private struct ContextMenuActionsPicker: View {
    private let items: [CMActionEntity]
    private let actionHandler: (String, CMElementTypeEntity) -> Void
    /// Returns true if the items contain at least one selected item. This is required to show the picker or the plain view based on the result.
    private var containsSelectedItem: Bool {  items.contains { $0.state == .on } }
    @State private var selectionIndex: Int

    init(items: [CMActionEntity], actionHandler: @escaping (String, CMElementTypeEntity) -> Void) {
        self.items = items
        self.actionHandler = actionHandler
        self.selectionIndex = items.firstIndex { $0.state == .on } ?? -1
    }

    var body: some View {
        Section {
            if containsSelectedItem {
                pickerView
            } else {
                content
            }
        }
    }

    private var pickerView: some View {
        Picker("", selection: $selectionIndex) {
            content
        }
        .onChange(of: selectionIndex) { newValue in
            handleSelection(at: newValue)
        }
    }

    private var content: some View {
        ForEach(0..<items.count, id: \.self) { index in
            ContextMenuActionItemView(item: items[index], actionHandler: actionHandler)
        }
    }

    private func handleSelection(at index: Int) {
        let item = items[index]
        var actionModel = item.toContextMenuModel()
        actionHandler(actionModel.data?.identifier ?? "", actionModel.type)
    }
}

private struct ContextMenuActionItemView: View {
    let item: CMActionEntity
    let actionHandler: (String, CMElementTypeEntity) -> Void

    var body: some View {
        var actionModel = item.toContextMenuModel()
        Button {
            actionHandler(actionModel.data?.identifier ?? "", actionModel.type)
        } label: {
            ContextMenuDataModelView(model: actionModel.data)
        }
    }
}

private struct ContextMenuDataModelView: View {
    let model: ContextMenuDataModel?

    var body: some View {
        if let model {
            if let image = model.image {
                Label {
                    Text(model.title ?? "")
                } icon: {
                    Image(uiImage: image)
                }
            } else {
                Text(model.title ?? "")
            }

            if let subtitle = model.subtitle {
                Text(subtitle)
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    let selectOption = CMActionEntity(type: .display(actionType: .select), isEnabled: false, state: .off)
    let selectOptionGroup = CMEntity(
        type: .unknown,
        displayInline: false,
        currentChatStatus: nil,
        currentSortType: nil,
        currentFilterType: nil,
        dndRemainingTime: nil,
        children: [selectOption]
    )

    let thumbnailOption = CMActionEntity(type: .display(actionType: .thumbnailView), isEnabled: false, state: .on)
    let listViewOption = CMActionEntity(type: .display(actionType: .listView), isEnabled: false, state: .off)
    let viewOptionGroup = CMEntity(
        type: .unknown,
        displayInline: false,
        currentChatStatus: nil,
        currentSortType: nil,
        currentFilterType: nil,
        dndRemainingTime: nil,
        children: [thumbnailOption, listViewOption]
    )

    let menu = CMEntity(
        type: .unknown,
        displayInline: false,
        currentChatStatus: nil,
        currentSortType: nil,
        currentFilterType: nil,
        dndRemainingTime: nil,
        children: [selectOptionGroup, viewOptionGroup]
    )

    return ContextMenuWithButtonView(menu: menu) {
        Button("Show context menu") {}
    } actionHandler: { _, _ in}
}

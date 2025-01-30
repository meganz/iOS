import Combine
import MEGADomain
import SwiftUI

@MainActor
public final class SetSelection: ObservableObject {
    public enum SelectionMode: Sendable {
        case single
        case multiple
    }
    
    @Published public var editMode: EditMode = .inactive {
        willSet {
            if !newValue.isEditing {
                selectedSets.removeAll()
            }
        }
    }
    @Published public private(set) var selectedSets = Set<SetIdentifier>()
    
    let mode: SelectionMode
    
    public init(
        mode: SelectionMode = .multiple,
        editMode: EditMode = .inactive
    ) {
        self.mode = mode
        self.editMode = editMode
    }
    
    public func toggle(_ setIdentifier: SetIdentifier) {
        if selectedSets.contains(setIdentifier) {
            selectedSets.remove(setIdentifier)
        } else {
            addItem(setIdentifier)
        }
    }
    
    private func addItem(_ setIdentifier: SetIdentifier) {
        if mode == .single {
            selectedSets = [setIdentifier]
        } else {
            selectedSets.insert(setIdentifier)
        }
    }
}

extension SetSelection {
    ///  Determine if the Set should show disabled for single selection mode
    /// - Parameter setIdentifier: set identifier to observe disabled state
    /// - Returns: `true` if album should show disabled state and false if not in disabled state
    func shouldShowDisabled(for setIdentifier: SetIdentifier) -> AnyPublisher<Bool, Never> {
        guard mode == .single else {
            return Just(false).eraseToAnyPublisher()
        }
        return $selectedSets
            .map(\.isNotEmpty)
            .removeDuplicates()
            .combineLatest($selectedSets.map { $0.contains(setIdentifier) })
            .map {
                guard $0 else { return false}
                return !$1
            }
            .debounceImmediate(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

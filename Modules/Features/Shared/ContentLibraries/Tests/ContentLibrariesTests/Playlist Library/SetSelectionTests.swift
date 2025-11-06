import Combine
@testable import ContentLibraries
import MEGADomain
import SwiftUI
import Testing

@Suite("SetSelection Tests")
struct SetSelectionTests {
    
    @Suite("init")
    @MainActor
    struct Constructor {
        @Test(arguments: zip([SetSelection.SelectionMode.single, .multiple], [EditMode.inactive, .active, .transient]))
        func modesSetCorrectly(mode: SetSelection.SelectionMode, editMode: EditMode) {
            let sut = SetSelection(mode: mode, editMode: editMode)
            
            #expect(sut.mode == mode)
            #expect(sut.editMode == editMode)
        }
    }
    
    @Suite("Selected items")
    @MainActor
    struct SelectedItems {
       
        @Test("When toggling in single selection mode ensure previous selection removed")
        func singleSelectionEnsureCorrectSelectedItems() {
            let secondSelection = SetIdentifier(handle: 2)
            let sut = SetSelection(mode: .single)
            
            sut.toggle(SetIdentifier(handle: 1))
            sut.toggle(secondSelection)
            
            #expect(sut.selectedSets == [secondSelection])
        }
        
        @Test("When toggling in same item in single selection should remove")
        func singleSelectionSameItem() {
            let setIdentifier = SetIdentifier(handle: 1)
            let sut = SetSelection(mode: .single)
            
            sut.toggle(setIdentifier)
            #expect(sut.selectedSets == [setIdentifier])
            
            sut.toggle(setIdentifier)
            #expect(sut.selectedSets == [])
        }
        
        @Test("When toggling in single selection mode ensure previous selection removed")
        func multipleSelectionEnsureCorrectSelectedItems() {
            let firstSelection = SetIdentifier(handle: 1)
            let secondSelection = SetIdentifier(handle: 2)
            let sut = SetSelection(mode: .multiple)
            
            sut.toggle(firstSelection)
            sut.toggle(secondSelection)
            
            #expect(sut.selectedSets == [firstSelection, secondSelection])
        }
        
        @Test("When toggling in same item in single selection should remove")
        func multipleSelectionSameItemShouldRemoveItem() {
            let firstItem = SetIdentifier(handle: 1)
            let secondItem = SetIdentifier(handle: 2)
            let sut = SetSelection(mode: .multiple)
            
            sut.toggle(firstItem)
            sut.toggle(secondItem)
            #expect(sut.selectedSets == [firstItem, secondItem])
            
            sut.toggle(firstItem)
            #expect(sut.selectedSets == [secondItem])
        }
        
        @Test("When edit mode is not editing then selected sets should be removed")
        func editingEndsRemoveAll() {
            let sut = SetSelection(editMode: .active)
            sut.toggle(SetIdentifier(handle: 1))
            
            sut.editMode = .inactive
            
            #expect(sut.selectedSets.isEmpty)
        }
    }
    
    @Suite("Disabled")
    @MainActor
    struct DisabledState {
        @Test("multi selection should always return false for disabled")
        func multiSelection() async {
            let selection = SetIdentifier(handle: 1)
            let sut = SetSelection(mode: .multiple)
            
            await confirmation { confirmation in
                let invocationTask = Task {
                    for await isDisabled in sut.shouldShowDisabled(for: selection).values {
                        #expect(isDisabled == false)
                        confirmation()
                    }
                }
                try? await Task.sleep(nanoseconds: 150_000_000)
                sut.toggle(selection)
                
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    invocationTask.cancel()
                }
                await invocationTask.value
            }
        }
        
        @Test("single selection should show disabled if item is not selected")
        func singleSelection() async {
            let selection = SetIdentifier(handle: 1)
            let sut = SetSelection(mode: .single)
            
            await confirmation(expectedCount: 3) { confirmation in
                let invocationTask = Task {
                    var expectations = [false, true, false]
                    for await isDisabled in sut.shouldShowDisabled(for: selection).values {
                        #expect(isDisabled == expectations.removeFirst())
                        confirmation()
                    }
                }
                try? await Task.sleep(nanoseconds: 150_000_000)
                sut.toggle(SetIdentifier(handle: 2))
                try? await Task.sleep(nanoseconds: 150_000_000)
                sut.toggle(selection)
                
                Task {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    invocationTask.cancel()
                }
                await invocationTask.value
            }
        }
    }
}

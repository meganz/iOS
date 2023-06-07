import Foundation

protocol ElementStoreProtocol: Actor {
    associatedtype Element
    associatedtype ElementID: Hashable
    var currentIndex: Int { get }
    var isEmpty: Bool { get }
    var count: Int { get }
    var current: Element? { get set }
    
    func update(_ targetElements: [Element]) -> [Element]
    func remove(_ targetElements: [Element]) -> [Element]
    
    init(currentIndex: Int?, elements: [Element], elementsIdentifiedBy identifierKeyPath: KeyPath<Element, ElementID>)
}

actor ElementStore<Element, ElementID: Hashable>: ElementStoreProtocol {
    private let elementID: (Element) -> ElementID
    private var indicesByID: [ElementID: Int]
    private(set) var elements: [Element]
    var currentIndex: Int
    var isEmpty: Bool { count == .zero }
    var count: Int { elements.count }
    var current: Element? {
        get { elements[safe: currentIndex] }
        set {
            guard let newValue, let newIndex = indicesByID[elementID(newValue)] else { return }
            currentIndex = newIndex
        }
    }
    
    init(currentIndex: Int? = nil, elements: [Element] = [], elementsIdentifiedBy identifierKeyPath: KeyPath<Element, ElementID>) {
        let elementID: (Element) -> ElementID = { $0[keyPath: identifierKeyPath] }
        var indicesByID = elements.enumerated().reduce(into: [ElementID: Int]()) { partialResult, pair in
            let (i, element) = pair
            partialResult[element[keyPath: identifierKeyPath]] = i
        }
        self.elements = elements.reduce(into: [Element]()) { partialResult, element in
            let id = elementID(element)
            if let index = indicesByID[id], partialResult.indices ~= index { // Replace a duplicate ID
                partialResult[index] = element
                return
            }
            partialResult.append(element)
            indicesByID[id] = partialResult.count - 1
        }
        self.elementID = elementID
        self.indicesByID = indicesByID
        
        let index = currentIndex ?? .zero
        self.currentIndex = (elements.indices ~= index) ? index : .zero
    }
    
    private func reset(indicesAfter startIndex: Int) {
        guard startIndex < count, startIndex >= .zero else { return }
        elements.suffix(from: startIndex)
            .map(elementID)
            .enumerated()
            .forEach { offset, id in
                indicesByID[id] = startIndex + offset
            }
        
        if elements.indices ~= currentIndex { return }
        self.currentIndex = isEmpty ? .zero : count - 1
    }
    
    @discardableResult
    func remove(_ targetElements: [Element]) -> [Element] {
        var minIndexRemoved = isEmpty ? 0 : count - 1
        targetElements.compactMap {
            let id = elementID($0)
            guard let index = indicesByID[id] else { return nil }
            indicesByID[id] = nil
            return index
        }
        .sorted(by: >)
        .forEach {
            elements.remove(at: $0)
            minIndexRemoved = min(minIndexRemoved, $0)
        }
        
        reset(indicesAfter: minIndexRemoved)
        return elements
    }
    
    @discardableResult
    func update(_ targetElements: [Element]) -> [Element] {
        targetElements.forEach {
            guard let index = indicesByID[elementID($0)] else { return }
            elements[index] = $0
        }
        return elements
    }
}

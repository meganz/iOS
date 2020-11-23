import Foundation

func set<T, Value>(_ keyPath: WritableKeyPath<T, Value>, _ newValue: Value) -> (T) -> T {
    return { obj in
        var copyOfObj = obj
        copyOfObj[keyPath: keyPath] = newValue
        return copyOfObj
    }
}

import MEGASdk

public final class MockIntegerList: MEGAIntegerList {
    
    public private(set) var list: [Int64]
    
    public init(list: [Int64] = []) {
        self.list = list
    }
    
    public override var size: Int { list.count }
    
    public override func integer(at index: Int) -> Int64 {
        list[index]
    }
}

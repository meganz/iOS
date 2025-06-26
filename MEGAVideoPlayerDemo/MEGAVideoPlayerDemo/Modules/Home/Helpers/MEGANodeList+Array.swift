import MEGASdk

extension MEGANodeList {
    var toArray: [MEGANode] {
        var nodesArray: [MEGANode] = []
        for i in 0..<size {
            if let node = node(at: i) {
                nodesArray.append(node)
            }
        }
        return nodesArray
    }
}

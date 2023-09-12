import MEGASdk

extension MEGANodeList {
    func existsFileWithName(_ name: String) -> Bool {
        self.toNodeArray().contains { node in
            node.isFile() && node.name == name
        }
    }
}

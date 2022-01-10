import SwiftUI

struct PhotoBrowser: UIViewControllerRepresentable {
    var currentNode: MEGANode?
    var megaNodes: [MEGANode]
    
    init(node: MEGANode?, megaNodes: [MEGANode]) {
        self.currentNode = node
        self.megaNodes = megaNodes
    }
    
    func makeUIViewController(context: Context) -> MEGAPhotoBrowserViewController {
        let photoBrowserVC = MEGAPhotoBrowserViewController.photoBrowser(withMediaNodes: NSMutableArray(array: megaNodes), api: MEGASdkManager.sharedMEGASdk(), displayMode: .cloudDrive, presenting: currentNode, preferredIndex: 0)
        photoBrowserVC?.needsReload = true
        
        return photoBrowserVC ?? MEGAPhotoBrowserViewController()
    }
    
    func updateUIViewController(_ uiViewController: MEGAPhotoBrowserViewController, context: Context) {}
}

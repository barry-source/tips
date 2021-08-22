//
//  BinarySearchTreeController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/10.
//

import UIKit

class BinarySearchTreeController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let l = TreeNode(4, TreeNode(3), TreeNode(5))
        let root = TreeNode(1, l, TreeNode(2))
        print(inorderTraversal(root))
//        print(preorderTraversal(root))
        // Do any additional setup after loading the view.
    }
    


}



extension BinarySearchTreeController {
    
    /*
     94. 二叉树的中序遍历
     https://leetcode-cn.com/problems/binary-tree-inorder-traversal/
     */
    
//    func inorderTraversal(_ root: TreeNode?) -> [Int] {
//        guard let root = root else { return [] }
//
//        var seq: [Int] = []
//        seq += inorderTraversal(root.left)
//        seq.append(root.val)
//        seq += inorderTraversal(root.right)
//        return seq
//    }
    
    // 利用栈
    func inorderTraversal(_ root: TreeNode?) -> [Int] {
        if root == nil { return [] }
        var stack: [TreeNode] = []
        var result: [Int] = []
        var node = root
        
        while node != nil || !stack.isEmpty {
            while node != nil {
                stack.append(node!)
                print(stack.map { $0.val })
                node = node?.left
            }
            let temp = stack.popLast()!
            result.append(temp.val)
            node = temp.right
        }
        return result
    }

}

extension BinarySearchTreeController {
    /*
     144. 二叉树的前序遍历
     https://leetcode-cn.com/problems/binary-tree-inorder-traversal/
     */
    
    func preorderTraversal(_ root: TreeNode?) -> [Int] {
        guard let root = root else { return [] }
            
        var seq: [Int] = []
        seq.append(root.val)
        seq += inorderTraversal(root.left)
        seq += inorderTraversal(root.right)
        return seq
    }
}

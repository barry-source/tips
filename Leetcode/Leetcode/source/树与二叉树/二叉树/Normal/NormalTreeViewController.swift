//
//  NormalTreeViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/31.
//

import UIKit

class NormalTreeViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    /*
     翻转二叉树
     https://leetcode-cn.com/problems/invert-binary-tree/
     */

    func invertTree(_ root: TreeNode?) -> TreeNode? {
        
//        if root == nil { return root }
//        let temp = root?.left
//        root?.left = root?.right
//        root?.right = temp
//        invertTree(root?.left)
//        invertTree(root?.right)
//        return root
        
//
//        guard let root = root else { return nil }
//        (root.left, root.right) = (invertTree(root.right), invertTree(root.left))
//        return root
        
        
        // 广度优先
        guard let root = root else { return nil }
        var stack = [root]
        while !stack.isEmpty {
            let node = stack.popLast()
            if let node = node {
                (node.left, node.right) = (node.right, node.left)
            }
//            swap(&node!.left, &node!.right)
            if let left = node!.left { stack.append(left) }
            if let right = node!.right { stack.append(right) }
        }
        return root
        
    }
}

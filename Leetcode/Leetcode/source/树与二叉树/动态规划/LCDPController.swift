//
//  LCDPController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/10.
//

import UIKit

class LCDPController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let root = TreeNode(3)
        let l = TreeNode(2)
        let r = TreeNode(3)
//        let ll = TreeNode(4)
        let lr = TreeNode(3)
        let rr = TreeNode(1)
        root.left = l
        root.right = r
//        l.left = ll
        l.right = lr
        r.right = rr
        
        print(rob(root))
        
        var array:[Character] = ["a","a","b","b","c","c","c"]
        print(compress(&array))
        print(array)

    }
    
    
    /*打家劫舍*/
    func rob(_ root: TreeNode?) -> Int {
        if root == nil {
            return 0
        }
        return robDP(root).max() ?? 0
    }

    func robDP(_ root: TreeNode?) -> [Int] {
        guard let node = root else {
            print([0, 0])
            return [0, 0]
        }
        print("当前node值：\(node.val)")
        let leftInfo = robDP(root?.left)
        let rightInfo = robDP(root?.right)
        
        // 当前节点有2个选择
        // 1: 偷当前节点, 那么左右节点就不能偷了
        let tou = node.val + leftInfo[0] + rightInfo[0]
        // 2: 不偷当前节点, 那么我看看 左节点偷利益大呢还是不偷利益大呢？
        let butou = (leftInfo.max() ?? 0) + (rightInfo.max() ?? 0)
        print([butou, tou])
        return [butou, tou]
    }

    
    
    
    /*字符串压缩*/
    func compress(_ chars: inout [Character]) -> Int {
        if chars.count <= 1 {
            return chars.count
        }
        
        var anchor = 0
        var write = 0
        for read in chars.indices {
            
            if read == chars.count - 1 || chars[read] != chars[read + 1] {
                chars[write] = chars[anchor]
                write += 1
                if read > anchor {
                    for c in String(read - anchor + 1) {
                        chars[write] = c
                        write += 1
                    }
                }
                anchor = read + 1
            }
        }
        return write
    }
    
}

//
//  BFSViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/29.
//

import UIKit

class BFSViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let grid = [[0,0,1,0,0,0,0,1,0,0,0,0,0],[0,0,0,0,0,0,0,1,1,1,0,0,0],[0,1,1,0,1,0,0,0,0,0,0,0,0],[0,1,0,0,1,1,0,0,1,0,1,0,0],[0,1,0,0,1,1,0,0,1,1,1,0,0],[0,0,0,0,0,0,0,0,0,0,1,0,0],[0,0,0,0,0,0,0,1,1,1,0,0,0],[0,0,0,0,0,0,0,1,1,0,0,0,0]]
//        print(maxAreaOfIsland(grid))
        let gridC: [[Character]] = [["1","1","0","0","0"],
                                    ["1","1","0","0","0"],
                                    ["0","0","1","0","0"],
                                    ["0","0","0","1","1"]]
        print(numIslands(gridC))
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


// 二维平面搜索
// 左右上下
var directions: [(Int, Int)] = [(-1, 0), (1, 0), (0, -1), (0, 1)]

extension BFSViewController {
    /*
     200. 岛屿数量
     https://leetcode-cn.com/problems/number-of-islands/
     */
    
    func numIslands(_ grid: [[Character]]) -> Int {
        var grid = grid
        let row = grid.count, column = grid[0].count
        var count = 0
        for i in 0..<row {
            for j in 0..<column {
                if grid[i][j] == "1" {
                    bfs(&grid, row, column, i, j)
                    count += 1
                }
            }
        }
        return count
    }
    
    func bfs(_ grid: inout [[Character]], _ row: Int, _ column: Int, _ i: Int, _ j: Int) {
        var queue: [(Int, Int)] = [(i, j)]
        grid[i][j] = "0"
        while !queue.isEmpty {
            let first = queue.removeFirst()
            for direction in directions {
                let (newX, newY) = (first.0 + direction.0, first.1 + direction.1)
                if (newX >= 0 && newX < row && newY >= 0 && newY < column) && (grid[newX][newY] == "1") {
                    queue.append((newX, newY))
                    grid[newX][newY] = "0"
                }
            }
        }
    }
    
    /*
     剑指 Offer II 105. 岛屿的最大面积
     https://leetcode-cn.com/problems/ZL6zAn/
     */
    func maxAreaOfIsland(_ grid: [[Int]]) -> Int {
        let row = grid.count, column = grid[0].count
        let columnArray = Array(repeating: false, count: column)
        var visited: [[Bool]] = Array(repeating: columnArray, count: row)
        var maxArea = 0
        for i in 0..<row {
            for j in 0..<column {
                if canSearch(grid, visited, i, j) {
                    maxArea = max(maxArea, bfs(grid, row, column, &visited, i, j))
                }
            }
        }
        return maxArea
    }
    
    func bfs(_ grid: [[Int]], _ row: Int, _ column: Int, _ visited: inout [[Bool]], _ i: Int, _ j: Int) -> Int {
        var count = 0
        var queue: [(Int, Int)] = [(i, j)]
        visited[i][j] = true
        while !queue.isEmpty {
            let first = queue.removeFirst()
            count += 1
            for direction in directions {
                let (newX, newY) = (first.0 + direction.0, first.1 + direction.1)
                if isInArea(row, column, newX, newY) && canSearch(grid, visited, newX, newY) {
                    queue.append((newX, newY))
                    visited[newX][newY] = true
                }
            }
        }
        return count
    }
    
    // 是否可以遍历
    func canSearch(_ grid: [[Int]], _ visited: [[Bool]], _ i: Int, _ j: Int) -> Bool {
        return grid[i][j] == 1 && !visited[i][j]
    }
    
    // 是否在指定grid范围内
    func isInArea(_ row: Int, _ column: Int, _ i: Int, _ j: Int) -> Bool {
        return i >= 0 && i < row && j >= 0 && j < column
    }
    
}

// 广度优先
extension BFSViewController {
    

    /*
     993. 二叉树的堂兄弟节点
     https://leetcode-cn.com/problems/cousins-in-binary-tree/
     */
    
    func isCousins(_ root: TreeNode?, _ x: Int, _ y: Int) -> Bool {
        guard let root = root else { return false }
        //dic[key]===> key: 结点值， value:节点的父节点的值和深度
        var dic = [Int: (Int, Int)]()
        var queue: [TreeNode] = [root]
        var d = 0
        while !queue.isEmpty {
            d = d + 1
            for _ in queue {
                let node = queue.removeFirst()
                if let ln = node.left {
                    queue.append(ln)
                    dic[ln.val] = (node.val, d)
                }
                if let rn = node.right {
                    queue.append(rn)
                    dic[rn.val] = (node.val, d)
                }
            }
        }
        //父节点不相等但是深度相等 就返回true
        if let xi = dic[x], let yi = dic[y], xi.0 != yi.0 && xi.1 == yi.1 {
            return true
        }
        return false
    }
    
    /*
     429. N 叉树的层序遍历
     https://leetcode-cn.com/problems/n-ary-tree-level-order-traversal/
     */
    func levelOrder(_ root: Node?) -> [[Int]] {
        guard let root = root else { return [] }

        var result: [[Int]] = []
        var queue: [Node] = [root]

        while !queue.isEmpty {
            var levelResult: [Int] = []

            for _ in 0 ..< queue.count {
                let node = queue.removeFirst()
                levelResult.append(node.val)
                queue.append(contentsOf: node.children)
            }

            result.append(levelResult)
        }

        return result
    }
    
    /*
     103. 二叉树的锯齿形层序遍历
     https://leetcode-cn.com/problems/binary-tree-zigzag-level-order-traversal/
     */
    func zigzagLevelOrder(_ root: TreeNode?) -> [[Int]] {
        guard let root = root else { return [] }

        var result: [[Int]] = []
        var queue: [TreeNode] = [root]

        var level = 0
        while !queue.isEmpty {
            var levelResult: [Int] = []

            for _ in 0 ..< queue.count {
                let node = queue.removeFirst()
                if level % 2 == 0 {
                    levelResult.append(node.val)
                } else {
                    levelResult.insert(node.val, at: 0)
                }
                
                if let left = node.left { queue.append(left) }
                if let right = node.right { queue.append(right) }
            }

            result.append(levelResult)
            level += 1
        }

        return result
    }
    
    
    /*
     剑指 Offer 32 - I. 从上到下打印二叉树
     https://leetcode-cn.com/problems/cong-shang-dao-xia-da-yin-er-cha-shu-lcof/
     */
    
    func levelOrder(_ root: TreeNode?) -> [Int] {
        guard let root = root else {
            return []
        }
        var result: [Int] = []
        var queue: [TreeNode] = [root]
        while !queue.isEmpty {
            for _ in queue {
                let node = queue.removeFirst()
                result.append(node.val)
                if let left = node.left { queue.append(left) }
                if let right = node.right { queue.append(right) }
            }
        }
        return result
    }
    
    
    /*
     剑指 Offer 32 - III. 从上到下打印二叉树 III
     https://leetcode-cn.com/problems/cong-shang-dao-xia-da-yin-er-cha-shu-iii-lcof/
     */
    func levelOrderIII(_ root: TreeNode?) -> [[Int]] {
        guard let root = root else { return [] }

        var result: [[Int]] = []
        var queue: [TreeNode] = [root]

        var level = 0
        while !queue.isEmpty {
            var levelResult: [Int] = []

            for _ in 0 ..< queue.count {
                let node = queue.removeFirst()
                if level % 2 == 0 {
                    levelResult.append(node.val)
                } else {
                    levelResult.insert(node.val, at: 0)
                }
                
                if let left = node.left { queue.append(left) }
                if let right = node.right { queue.append(right) }
            }

            result.append(levelResult)
            level += 1
        }

        return result
    }
    
    
    /*
     102. 二叉树的层序遍历
     https://leetcode-cn.com/problems/binary-tree-level-order-traversal/
     剑指 Offer 32 - II. 从上到下打印二叉树 II
     https://leetcode-cn.com/problems/cong-shang-dao-xia-da-yin-er-cha-shu-ii-lcof/
     */
    
    func levelOrder(_ root: TreeNode?) -> [[Int]] {
        guard let root = root else { return [] }

        var result: [[Int]] = []
        var queue: [TreeNode] = [root]

        while !queue.isEmpty {
            var levelResult: [Int] = []

            for _ in 0 ..< queue.count {
                let node = queue.removeFirst()
                levelResult.append(node.val)
                if let left = node.left { queue.append(left) }
                if let right = node.right { queue.append(right) }
            }

            result.append(levelResult)
        }

        return result
    }
    
    /*
     107. 二叉树的层序遍历 II
     https://leetcode-cn.com/problems/binary-tree-level-order-traversal-ii/
     */
    func levelOrderBottom(_ root: TreeNode?) -> [[Int]] {
        guard let root = root else { return [] }
        var result: [[Int]] = []
        var queue: [TreeNode] = [root]
        while !queue.isEmpty {
            var temp: [Int] = []
            for _ in queue {
                let first = queue.removeFirst()
                temp.append(first.val)
                if let left = first.left { queue.append(left) }
                if let right = first.right { queue.append(right) }
            }
            result.insert(temp, at: 0)
        }
        return result
    }
    
    /*
     「力扣」第 323 题 无向图中连通分量的数目
     https://leetcode-cn.com/problems/number-of-connected-components-in-an-undirected-graph/
     */
    
    func countComponents(_ n:Int,_ edges:inout [[Int]]) -> Int {
        var res: Int = n
        var root:[Int] = [Int](repeating:0,count:n)
        for i in 0..<n {
            root[i] = i
        }
        for a in edges
        {
            var x:Int = find(&root, a[0])
            var y:Int = find(&root, a[1])
            if x != y
            {
                res -= 1
                root[y] = x
            }
        }
        return res
    }

    func find(_ root:inout [Int],_ i:Int) -> Int {
        var i = i
        while(root[i] != i)
        {
            i = root[i]
        }
        return i
    }
    
    
}

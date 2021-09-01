//
//  SwordOfferViewController+Ten.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/22.
//

import Foundation

// 反转链表
var arr = [Int]()

// 用两个栈实现队列
var stack1: [Int] = []
var stack2: [Int] = []

extension SwordOfferViewController {
    
    /*
     剑指 Offer 03. 数组中重复的数字
     https://leetcode-cn.com/problems/shu-zu-zhong-zhong-fu-de-shu-zi-lcof/
     */
    
    func findRepeatNumber(_ nums: [Int]) -> Int {
        var nums = nums
        var index = 0
        while index < nums.count {
            if index == nums[index] {
                index += 1
                continue
            }
            if nums[nums[index]] == nums[index] {
                return nums[index]
            }
            (nums[index], nums[nums[index]]) = (nums[nums[index]], nums[index])
        }
        return -1
        
//        var nums = nums
//        for i in 0 ..< nums.count {
//            if i == nums[i] { continue }
//            if nums[i] == nums[nums[i]] {
//                return nums[i]
//            }
//            nums.swapAt(i, nums[i])
//            if i == nums.count - 1 {
//                if nums[i] == nums[nums[i]] {
//                    return nums[i]
//                }
//            }
//        }
//        return -1
    }
    
    
//    func findRepeatNumber(_ nums: [Int]) -> Int {
//        var hashSet: Set<Int> = []
//        for num in nums {
//            if hashSet.contains(num) {
//                return num
//            }
//            hashSet.insert(num)
//        }
//        return -1
//    }


    /*
     剑指 Offer 04. 二维数组中的查找
     https://leetcode-cn.com/problems/er-wei-shu-zu-zhong-de-cha-zhao-lcof/
     解：
     1: 从右上角开始，v = [i][j] i = 0, j = matrix[0].count
     2: 如果：v > target，那么整列都不符合，那么让 j--
     3: 如果：v < target, 说明[i][0～j]都不符合，那么让i--
     4: 直到找到v=target，或者发生越界 i<0||j<0||j>=matrix[0].count||i>=matrix.count
     */
    func findNumberIn2DArray(_ matrix: [[Int]], _ target: Int) -> Bool {
        
        // 暴力求解比较耗时
        // 下在是根据自增的特点处理
        if matrix.count == 0 ||
            matrix[0].count == 0 ||
            matrix[0][0] > target ||
            matrix.last!.last! < target {
            return false
        }
        let rowCount = matrix.count
        let colCount = matrix[0].count
        
        var i = 0, j = colCount - 1
        
        while i >= 0, j >= 0, i < rowCount, j < colCount {
            if matrix[i][j] == target {
                return true
            } else if matrix[i][j] > target {       // 说明[i~len][j]都 > target
                j -= 1
            } else {                                // 说明[i][0~j]都 < target
                i += 1
            }
        }
        
        return false
//        var row = matrix.count - 1 , col = 0
//        while row >= 0 && col <= matrix[0].count-1 {
//            if matrix[row][col] > target {
//                row -= 1
//            }else if matrix[row][col] < target{
//                col += 1
//            }else{
//                return true
//            }
//        }
//
//        return false
    }
    
    /*
     剑指 Offer 05. 替换空格
     https://leetcode-cn.com/problems/ti-huan-kong-ge-lcof/
     */
    
    func replaceSpace(_ s: String) -> String {
//        var res = ""
//        for char in s {
//            if char == " " {
//                res.append("%20")
//            } else {
//                res.append(char)
//            }
//        }
//        return res
        
        // 双指针法
        var count: Int = 0
        s.forEach { item in
            if item == " "{
                count += 1
            }
        }
        var resultArr = [Character](repeating: Character(" "), count: s.count + 2 * count)
        var index: Int = resultArr.count - 1
        for item in s.reversed() {
            if item == " " {
                resultArr[index] = Character("0")
                index -= 1
                resultArr[index] = Character("2")
                index -= 1
                resultArr[index] = Character("%")
                index -= 1
            } else {
                resultArr[index] = item
                index -= 1
            }
        }
        return String(resultArr)
    }
    
    /*
     剑指 Offer 06. 从尾到头打印链表
     https://leetcode-cn.com/problems/cong-wei-dao-tou-da-yin-lian-biao-lcof/
     */
    
//    func reversePrintInsertArray(_ head: ListNode?) -> [Int] {
//        var result: [Int] = []
//        var node = head
//        while node != nil {
//            result.insert(node!.val, at: 0)
//            node = node?.next
//        }
//        return result
//    }

    // 递归调用
    func reversePrintInsertArray(_ head: ListNode?) -> [Int] {
        return reversePrint(head)
    }
    
    func reversePrint(_ head: ListNode?) -> [Int] {
        if head == nil { return [] }
        _ = reversePrint(head?.next)
        arr.append(head!.val)
        return arr
    }

    /*
     剑指 Offer 07. 重建二叉树
     https://leetcode-cn.com/problems/zhong-jian-er-cha-shu-lcof/
     */
    func buildTree(_ preorder: [Int], _ inorder: [Int]) -> TreeNode? {
        if preorder.count == 0 || inorder.count == 0 { return nil }
        
        //构建二叉树根结点
        let root: TreeNode? = TreeNode(preorder[0])
        
        //对中序序列进行遍历
        for (index, num) in inorder.enumerated() {
            // 如果找到根节点
            if num == preorder[0] {
                root?.left = buildTree(Array(preorder[1..<index+1]), Array(inorder[0..<index]) )
                root?.right = buildTree(Array(preorder[index+1..<preorder.endIndex]), Array(inorder[index+1..<inorder.endIndex]))
            }
        }
        
        return root
    }
    

    /*
     剑指 Offer 09. 用两个栈实现队列
     https://leetcode-cn.com/problems/yong-liang-ge-zhan-shi-xian-dui-lie-lcof/
     */
    
    func appendTail(_ value: Int) {
        stack1.append(value)
    }
    
    func deleteHead() -> Int {
        if stack2.isEmpty {
            while let head = stack1.popLast() {
                stack2.append(head)
            }
        }
        return stack2.popLast() ?? -1
    }
    /*
     
     */
    
    
    /*
     
     */
    
    func topKFrequent(_ nums: [Int], _ k: Int) -> [Int] {

        var array: [(Int, Int)] = nums.reduce(into: [Int: Int]()) { $0[$1, default: 0] += 1 }
                        .map { (key: $0.key, value: $0.value) }
        print(array)
        topK(array: &array, low: 0, high: array.count - 1, k: k)
        return Array(array[0...k-1]).map { $0.0 }
    }
    
    func topK(array: inout [(Int, Int)], low: Int, high: Int, k: Int) {
        guard low < high else { return }
        let i = partion(array: &array, low: low, high: high)
        let count = i - low
        print(count)
        if count > k {
            topK(array: &array, low: low, high: i - 1, k: k)
        } else {
            topK(array: &array, low: i + 1, high: high, k: k - i)
        }
    }

    // 快排的分治
    func partion(array: inout [(Int, Int)], low: Int, high: Int) -> Int {
        
        var (iLow, iHigh) = (low, high)
        let priot = array[low]
        print("low:\(low)--high:\(high)")
        print("priot: \(priot)")
        while iLow != iHigh {
            while iLow < iHigh && array[iHigh].1 <= priot.1 {
                iHigh -= 1
            }
            while iLow < iHigh && array[iLow].1 >= priot.1 {
                iLow += 1
            }
            if iLow < iHigh {
                (array[iLow], array[iHigh]) = (array[iHigh], array[iLow])
            }
            print(array)
        }
        array[low] = array[iLow]
        array[iLow] = priot
        print("======")
        print(array)
        print("------")
        return iLow

//        let pivot = array[high].1
//        var i = low
//        for j in low...high {
//            if array[j].1 > pivot {
//                array.swapAt(i, j)
//                i += 1
//            }
//        }
//        array.swapAt(i, high)
//        return i
    }
}

//
//  JingDongViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/15.
//

import UIKit

class JingDongViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let header = createList1([1,2,4]).0
//        let header1 = createList1([1,3,4]).0
//        printList(mergeTwoLists(header, header1))
//
//        print(reverse(123))
        
        print(decodeString("3[a]2[bc]"))
    }
    

}


// easy

extension JingDongViewController {
    
    func permute(_ nums: [Int]) -> [[Int]] {
        return next(nums, result: [[nums[0]]], index: 1)
    }


    func next(_ nums: [Int], result: [[Int]], index: Int) -> [[Int]] {
        if index >= nums.count {
            return result
        }
        let inserted = nums[index]
        var newResult: [[Int]] = []
        for e in result {
            for i in 0...index {
                var old = e
                old.insert(inserted, at: i)
                newResult.append(old)
            }
        }
        return next(nums, result: newResult, index: index + 1)
    }
    
    func merge(_ A: inout [Int], _ m: Int, _ B: [Int], _ n: Int) {
        var a = m - 1
        var b = n - 1
        var cur = m + n - 1
        while a >= 0 && b >= 0 {
            if A[a] < B[b] {
                A[cur] = B[b]
                b -= 1
            } else {
                A[cur] = A[a]
                a -= 1
            }
            cur -= 1
        }
        // 遍历B中剩余的元素，全部添加到数组A中
        if b != -1 {
            for i in 0...b {
                A[i] = B[i]
            }
        }
       
    }

    /*
     7. 整数反转
     https://leetcode-cn.com/problems/reverse-integer/
     */
    
    func reverse(_ x: Int) -> Int {
        if x < Int32.min || x > Int32.max {
            return 0
        }
        // 区分正负效率高些
        let hasSign =  x < 0
        var x = x
        var reminder = 0
        while x != 0 {
            reminder = reminder * 10 + x % 10
            x = x / 10
            if reminder < Int32.min || reminder > Int32.max {
                return 0
            }
        }
        return hasSign ? -reminder : reminder
    }
    
    /*
     415. 字符串相加
     https://leetcode-cn.com/problems/add-strings/
     */
    
    // 递归实现
    func mergeTwoLists(_ l1: ListNode?, _ l2: ListNode?) -> ListNode? {
        if l1 == nil { return l2 }
        if l2 == nil { return l1 }
        if (l1?.val ?? 0) < (l2?.val ?? 0) {
            l1?.next = mergeTwoLists(l1?.next, l2)
            return l1
        } else {
            l2?.next = mergeTwoLists(l2?.next, l1)
            return l2
        }
    }
    // 常规实现
//    func mergeTwoLists(_ l1: ListNode?, _ l2: ListNode?) -> ListNode? {
//        if l1 == nil {
//            return l2
//        }
//        if l2 == nil {
//            return l1
//        }
//        var l1 = l1, l2 = l2
//        let dummyHead: ListNode? = ListNode(-1)
//        var tempHead = dummyHead
//
//        while l1 != nil && l2 != nil {
//            if (l1?.val ?? 0) < (l2?.val ?? 0) {
//                tempHead?.next = l1
//                tempHead = l1
//                l1 = l1?.next
//            } else {
//                tempHead?.next = l2
//                tempHead = l2
//                l2 = l2?.next
//            }
//        }
//
//        tempHead?.next = l1 ?? l2
//        let head = dummyHead?.next
//        dummyHead?.next = nil
//        return head
//    }
    
}

extension JingDongViewController {
    
    /*
     4.寻找两个正序数组的中位数
     https://leetcode-cn.com/problems/median-of-two-sorted-arrays/
     */
    
    func findMedianSortedArrays(_ nums1: [Int], _ nums2: [Int]) -> Double {
        
        var i = 0, j = 0, last = 0, current = 0
        while i + j <= (nums1.count + nums2.count) / 2 {
            last = current
            
            if j >= nums2.count || i < nums1.count && nums2[j] >= nums1[i] {
                current = nums1[i]
                i += 1
            } else {
                current = nums2[j]
                j += 1
            }
        }
        
        if (nums2.count + nums1.count) % 2 == 0 {
            return Double(last + current) / 2.0
        } else {
            return Double(current)
        }
        
//      var mergeArray = [Int](repeating: 0, count: nums1.count+nums2.count)
//      var i = 0
//      var j = 0
//
//      for index in 0..<mergeArray.count {
//
//        if (j >= nums2.count) || (i < nums1.count && nums1[i] <= nums2[j])  {
//          mergeArray[index] = nums1[i]
//          i+=1
//        } else  {
//          //! if (i >= nums1.count || j < nums2.count && nums1[i] > nums2[j]
//          mergeArray[index] = nums2[j]
//          j+=1
//        }
//
//      }
//
//      if mergeArray.count % 2 == 0 {
//        return Double(mergeArray[mergeArray.count/2-1] + mergeArray[mergeArray.count/2]) / 2.0
//      } else {
//        return Double(mergeArray[mergeArray.count/2])
//      }
    }
    /*
     394. 字符串解码
     https://leetcode-cn.com/problems/decode-string/
     */
    
    // "3[a]2[bc]"
    func decodeString(_ s: String) -> String {
        var currentResult = ""
        var repeatCount = 0
        var stack: [(Int, String)] = []
        // [ ]  count c
        // [(count, string), , , ]
        
        for c in s {
            if c == "[" {
                stack.append((repeatCount, currentResult))
                currentResult = ""
                repeatCount = 0
            } else if c == "]" {
                if let (repeatCount, lastResult) = stack.popLast() {
                    currentResult = lastResult + String(repeating: currentResult, count: repeatCount)
                }
            } else if c.isWholeNumber {
                repeatCount = repeatCount * 10 + (Int(String(c)) ?? 0)
            } else { // character
                currentResult += String(c)
            }
        }
        return currentResult
    }
}

extension JingDongViewController {
    
    
}




class Soulution {

    var res = [[Int]]()
    var path = [Int]()
    
    func combine(_ n: Int, _ k: Int) -> [[Int]] {
        guard n > 0, k > 0 else {
            return []
        }
        backtrace(n, k, start: 1)
        return res
    }

    func backtrace(_ n: Int, _ k: Int, start: Int) {
        if path.count == k {
            res.append(path)
            return
        }
        for i in start ..< n + 1 {
            path.append(i)
            backtrace(n, k, start: i + 1)
            path.removeLast()
        }
    }
}

//
//  LCMergetTwoSortedArrayController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/17.
//

import UIKit

class LCMergetTwoSortedArrayController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

//        var nums1 = [2,0]
//        let nums2 = [1]
//        merge(&nums1, 1, nums2, 1)
        
//        var nums1 = [1,2,3,0,0,0]
//        let nums2 = [2,5,6]
//        merge(&nums1, 3, nums2, 3)
        
//        var nums1 = [0]
//        let nums2 = [6]
//        merge(&nums1, 0, nums2, 1)
        
//        var nums1 = [4,5,6,0,0,0]
//        let nums2 = [1,2,3]
//        merge(&nums1, 3, nums2, 3)
        
        var nums1 = [4,0,0,0,0,0]
        let nums2 = [1,2,3,5,6]
        merge(&nums1, 1, nums2, 5)
        
        print(nums1)
        
    }
    
    /*
     插入再排序
     执行用时：12 ms, 在所有 Swift 提交中击败了85.36%的用户
     内存消耗：13.7 MB, 在所有 Swift 提交中击败了28.99%的用户
     */
//    func merge(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
//        for i in 0..<n {
//            nums1[m + i] = nums2[i]
//        }
//        nums1.sort { $0 < $1}
//    }
    
    
    /*
     // 从前往后排序
     执行用时：208 ms, 在所有 Swift 提交中击败了6.28%的用户
     内存消耗：13.6 MB, 在所有 Swift 提交中击败了35.71%的用户
     */
//    func merge(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
//        var i = 0
//        var currentLength = m
//        for toAdd in nums2 {
//            while i < currentLength && nums1[i] < toAdd {
//                i += 1
//            }
//            for k in (i..<currentLength).reversed() {
//                nums1[k + 1] = nums1[k]
//            }
//            nums1[i] = toAdd
//            currentLength += 1
//        }
//    }
    
    /*
     // 从后往前排序
     执行用时：12 ms, 在所有 Swift 提交中击败了85.36%的用户
     内存消耗：13.5 MB, 在所有 Swift 提交中击败了59.24%的用户
     */
    func merge(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
        var i = m - 1
        var j = n - 1
        while j >= 0 {
            if i >= 0 && nums1[i] > nums2[j] {
                nums1[i + j + 1] = nums1[i]
                i -= 1
            } else {
                nums1[i + j + 1] = nums2[j]
                j -= 1
            }
        }
    }
    
    // 新数组
    
    /*
     执行用时：12 ms, 在所有 Swift 提交中击败了85.36%的用户
     内存消耗：13.7 MB, 在所有 Swift 提交中击败了28.99%的用户
     */
//    func merge(_ nums1: inout [Int], _ m: Int, _ nums2: [Int], _ n: Int) {
//        if n == 0 { return }
//        var nums: [Int] = []
//        for _ in 0..<(m + n) {
//            nums.append(0)
//        }
//        var i = 0
//        var j = 0
//        var length = 0
//        for k in 0..<nums.count {
//            if i >= m || j >= n {
//                break
//            }
//            if nums1[i] > nums2[j] {
//                nums[k] = nums2[j]
//                j += 1
//            } else {
//                nums[k] = nums1[i]
//                i += 1
//            }
//            length += 1
//        }
//        if i < m {
//            for k in length..<nums.count {
//                nums[k] = nums1[i]
//                i += 1
//            }
//        }
//        if j < n {
//            for k in length..<nums.count {
//                nums[k] = nums2[j]
//                j += 1
//            }
//        }
//        nums1 = nums
//    }
    

}

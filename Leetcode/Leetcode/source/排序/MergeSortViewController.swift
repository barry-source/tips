//
//  MergeSort ViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/14.
//

import UIKit

class MergeSortViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(mergeSort([1,4,6,2,8]))
    }
    

    func mergeSort(_ array: [Int]) -> [Int] {
        var itemArray = array.map { [$0] }
        while itemArray.count > 1 {
            var i = 0
            while i < itemArray.count - 1 {
                itemArray[i] = merge(itemArray[i], itemArray[i + 1])
                itemArray.remove(at: i + 1)
                i += 1
            }
        }
        return itemArray.first ?? array
    }

    private func merge(_ left: [Int], _ right: [Int]) -> [Int] {
        var l = 0, r = 0
        var result: [Int] = []
        while l < left.count && r < right.count {
            if left[l] < right[r] {
                result.append(left[l])
                l += 1
            } else if left[l] > right[r] {
                result.append(right[r])
                r += 1
            } else {
                result.append(left[l])
                result.append(right[r])
                l += 1
                r += 1
            }
        }
        if l < left.count {
            for e in l ..< left.count {
                result.append(left[e])
            }
        }
        if r < right.count {
            for e in r ..< right.count {
                result.append(right[e])
            }
        }
        return result
    }

}

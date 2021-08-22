//
//  ShellSortViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/14.
// https://www.cnblogs.com/onepixel/articles/7674659.html

import UIKit

class ShellSortViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print(shellSort([1,4,6,2,8]))
    }
    

    func shellSort(_ array: [Int]) -> [Int] {
        var array = array
        let count = array.count
        var gap = count / 2
        while gap > 0 {
            var j = 0
            for i in array.indices {
                j = i
                let temp = array[i]
                while j >= gap, array[j - gap] > array[j] {
                    array[j] = array[j - gap]
                    j -= gap
                }
                array[j] = temp
                //   下面不符合插入排序
//                j = i + gap
//                while j >= gap, j < count, array[j - gap] > array[j] {
//                    (array[j], array[j - gap]) = (array[j - gap], array[j])
//                    j -= gap
//                }
            }
            gap /= 2
        }
        return array
    }
}

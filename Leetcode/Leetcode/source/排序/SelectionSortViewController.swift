//
//  SelectionSortViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/14.
// https://www.cnblogs.com/onepixel/articles/7674659.html

import UIKit

class SelectionSortViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(selectionSort([1,4,6,2,8]))
    }
    
    func selectionSort(_ array: [Int]) -> [Int] {
        var array = array
        let len = array.count
        var minIndex = 0
        for i in 1 ..< len - 1 {
            minIndex = i
            for j in (i + 1) ..< len  {
                if array[minIndex] > array[j] {
                    minIndex = j
                }
            }
            if i != minIndex {
                (array[i], array[minIndex]) = (array[minIndex], array[i])
            }
        }
        return array
    }
   
//
//    func selectionSort(_ array: [Int]) -> [Int] {
//        var array = array
//        let len = array.count
//        var minIndex = 0
//        for i in 0..<len - 1 {
//            minIndex = i
//            for j in (i + 1) ..< len {
//                if array[j] < array[minIndex] {
//                    minIndex = j
//                }
//            }
//            (array[i], array[minIndex]) = (array[minIndex], array[i])
//        }
//        return array
//    }
//
}

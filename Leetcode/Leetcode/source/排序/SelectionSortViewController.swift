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

        print(selectionSort1([6, 2, 1, 3, 5, 4]))
    }
    
    func selectionSort(_ array: [Int]) -> [Int] {
        var array = array
        let len = array.count
        var minIndex = 0
        for i in 0 ..< len - 1 {
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
   
    // 一次遍历找出最大值 + 最小值
    func selectionSort1(_ array: [Int]) -> [Int] {
        var array = array
        let len = array.count
        var minIndex = 0
        var maxIndex = 0
        for i in 0 ..< len / 2 {
            minIndex = i
            maxIndex = i
            for j in (i + 1) ..< len - i  {
                if array[minIndex] > array[j] {
                    minIndex = j
                }
                if array[minIndex] < array[j] {
                    maxIndex = j
                }
            }
            if minIndex == maxIndex { break }
            
            if i != minIndex {
                (array[i], array[minIndex]) = (array[minIndex], array[i])
            }
            if maxIndex == i { maxIndex = minIndex }
            
            let tailIndex = len - 1 - i
            if tailIndex != maxIndex {
                (array[tailIndex], array[maxIndex]) = (array[maxIndex], array[tailIndex])
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

//
//  BubbleSortViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/13.
// https://www.cnblogs.com/onepixel/articles/7674659.html

import UIKit

class BubbleSortViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(bubbleSort2([6, 2, 1, 3, 5, 4]))
        
    }
    
    func bubbleSort(_ array: [Int]) -> [Int] {
        var array = array
        let len = array.count
        for i in array.indices {
            for j in 0 ..< len - 1 - i {
                if array[j] > array[j + 1] {
                    (array[j], array[j + 1]) = (array[j + 1], array[j])
                }
            }
        }
        return array
    }
    
    func bubbleSort1(_ array: [Int]) -> [Int] {
        var array = array
        let len = array.count
        // 初始时 swapped 为 true，否则排序过程无法启动
        var swapped = true
        for i in array.indices {
            // 如果上次没有发生过交换，说明剩余部分已经有序，排序完成
            if !swapped {
                break
            }
            swapped = false
            for j in 0 ..< len - 1 - i {
                if array[j] > array[j + 1] {
                    (array[j], array[j + 1]) = (array[j + 1], array[j])
                    swapped = true
                }
            }
        }
        return array
    }
    
    func bubbleSort2(_ array: [Int]) -> [Int] {
        var array = array
        let len = array.count
        var swapped = true;
        // 最后一个没有经过排序的元素的下标
        var indexOfLastUnsortedElement = len - 1;
        // 上次发生交换的位置
        var swappedIndex = -1;
        
        while swapped {
            swapped = false
            for j in 0 ..< indexOfLastUnsortedElement {
                if array[j] > array[j + 1] {
                    (array[j], array[j + 1]) = (array[j + 1], array[j])
                    swapped = true
                    swappedIndex = j
                }
            }
            indexOfLastUnsortedElement = swappedIndex
        }
        return array
    }

}

//
//  CountSortViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/9/9.
//

import UIKit

class CountSortViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let array = [4,6,8,5,9]
        print(countingSort(array))
    }
    

    //MARK:计数排序
    func countingSort(_ arr:[Int]) -> [Int] {
        //1.找出待排序的数组中最大和最小的元素
        let maxNum = arr.max()!
        let minNum = arr.min()!
        //初始化一个与arr同样大小的数组
        var b:[Int] = [Int](repeating: 0, count: arr.count)
        //k的大小是要排序的数组中最大值和最小值之差 + 1
        let k = maxNum - minNum + 1
        var c = [Int](repeating: 0, count: k)
        //2.统计数组中每个值为的元素出现的次数，存入数组的第项
        for i in 0..<arr.count {
            //优化减小数组的大小,统计每个元素有几个
            c[arr[i] - minNum] += 1
        }
        print(c)
        //3.对所有的计数累加（从中的第一个元素开始，每一项和前一项相加）
        for i in 1..<c.count {
            //前缀和
            c[i] += c[i-1]
        }
        print(c)
        //4.反向填充目标数组
        for i in (0...arr.count - 1).reversed() {
            //按存取的方式取出c的元素
            c[arr[i] - minNum]  -= 1
            b[c[arr[i] - minNum]] = arr[i]
        }
        return b
    }

}

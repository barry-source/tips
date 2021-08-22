//
//  SwordOfferViewController+Ten.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/22.
//

import Foundation

extension SwordOfferViewController {
    
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

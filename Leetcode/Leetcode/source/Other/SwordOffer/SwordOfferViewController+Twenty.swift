//
//  SwordOfferViewController+Twenty.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/27.
//

import Foundation

extension SwordOfferViewController {
    /*
     剑指 Offer 11. 旋转数组的最小数字
     https://leetcode-cn.com/problems/xuan-zhuan-shu-zu-de-zui-xiao-shu-zi-lcof/
     二分法，
     
     */
    func minArray(_ numbers: [Int]) -> Int {
      var left = 0
      var right = numbers.count - 1
    
      while left < right {
      
        let mid = (left + right) / 2
      
        if numbers[mid] < numbers[right] {
          right = mid
        } else if numbers[mid] > numbers[right] {
          left = mid + 1
        } else {
          right -= 1
        }
      }
      return numbers[left]
    }
    
    /*
     剑指 Offer 12. 矩阵中的路径
     https://leetcode-cn.com/problems/ju-zhen-zhong-de-lu-jing-lcof/
     */
    func exist(_ board: [[Character]], _ word: String) -> Bool {
        var board = board
        let word = Array(word)
        let rows = board.count, columns = board[0].count
        for row in 0..<rows {
            for column in 0..<columns {
                if BFS(&board, word, row, column, 0) {
                    return true
                }
            }
        }
        return false
    }

    func BFS(_ board: inout [[Character]], _ word: [Character], _ row: Int, _ col: Int, _ k: Int)  -> Bool {
        if row < 0 || row >= board.count || col < 0 || col >= board[0].count || board[row][col] != word[k] {
            return false
        }
        if k == word.count - 1 {
            return true
        }
        // 标记已遍历过，用空串标记
        board[row][col] = " "
        // 上 || 下 || 左 || 右
        let next = BFS(&board, word, row - 1, col, k + 1) || BFS(&board, word, row + 1, col, k + 1)
                || BFS(&board, word, row, col - 1, k + 1) || BFS(&board, word, row, col + 1, k + 1)
        // 恢复原始数据
        board[row][col] = word[k]
        return next
    }

    
    /*
     剑指 Offer 14- II. 剪绳子 II
     https://leetcode-cn.com/problems/jian-sheng-zi-ii-lcof/
     */
    
//    func cuttingRope(_ n: Int) -> Int {
//
//    }
    
    func cuttingRope(_ n: Int) -> Int {
        if n < 4 {
            return n - 1
        }
        let a = n / 3, b = n % 3
        
        if b == 0 {
            return modPow(3, a) % 1_000_000_007
        }
        else if b == 1 {
            return modPow(3, a - 1) * 4 % 1_000_000_007
        }
        else {
            return modPow(3, a) * 2 % 1_000_000_007
        }
    }

    func modPow(_ x: Int, _ n: Int) -> Int {
        var res = 1
        var x = x
        var n = n
        
        while n > 0 {
            if n & 1 == 1 {
                res *= x
                res %= 1_000_000_007 // 限制了数据范围
            }
            x *= x
            x %= 1_000_000_007 // 限制了数据范围
            n >>= 1
        }
        
        return res
    }

}

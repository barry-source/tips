//
//  KuaishouViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/10.
//

import UIKit

class KuaishouViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        print(combinationSum([2,3,6,7], 7))
//        addStrings("1", "9")
        print(longestPalindrome("babad"))
//        print(countPrimeNum(6))
    }
    
    
}


// easy
extension KuaishouViewController {
    
    func levelOrder(_ root: TreeNode?) -> [[Int]] {
        guard let root = root else { return [] }

        var result: [[Int]] = []
        var queue: [TreeNode] = [root]

        while !queue.isEmpty {
            var levelResult: [Int] = []

            for _ in 0 ..< queue.count {
                let node = queue.removeFirst()
                levelResult.append(node.val)
                if let left = node.left { queue.append(left) }
                if let right = node.right { queue.append(right) }
            }

            result.append(levelResult)
        }

        return result
    }
    
    func lengthOfLongestSubstring(_ s: String) -> Int {
        if(s == "") { return 0 }
        var maxStr = String()
        var curStr = String()
        for char in s {
            while curStr.contains(char) {
                curStr.removeFirst()
            }
            curStr.append(char)
            if curStr.count > maxStr.count {
                maxStr = curStr
            }
        }
        return maxStr.count
    }
//    func lengthOfLongestSubstring(_ s: String) -> Int {
//        var dic = [Character: Int]()
//        var start = 0
//        var result = 0
//        for (index, char) in s.enumerated() {
//            let previousIndex = dic[char] ?? -1
//            if previousIndex >= start {
//                start = previousIndex + 1
//            }
//            let currentLength = index - start + 1
//            result = max(result, currentLength)
//            dic[char] = index
//        }
//        return result
//    }
    /*
     39. 组合总和
     https://leetcode-cn.com/problems/combination-sum/
     */
    
    func combinationSum(_ candidates: [Int], _ target: Int) -> [[Int]] {
        var result = [[Int]]()
        if candidates.count == 0 {
            return result
        }

        // 先排序原数组
        let newCandidates = candidates.sorted()
        dfs(newCandidates, target, 0, [], &result)
        
        return result
    }

    func dfs(_ candidates: [Int], _ target: Int, _ begin: Int, _ path: [Int], _ result: inout [[Int]]) {
        if target == 0 {
            result.append(path)
            return
        }
        for i in begin..<candidates.count {
            if target - candidates[i] < 0 { return }
            var path = path
            path.append(candidates[i])
            dfs(candidates, target - candidates[i], i, path, &result)
        }
    }
    /*
     剑指 Offer 58 - II. 左旋转字符串
     https://leetcode-cn.com/problems/zuo-xuan-zhuan-zi-fu-chuan-lcof/
     */
    
    func reverseLeftWords(_ s: String, _ n: Int) -> String {
//        return String(s.dropFirst(n)) + String(s.prefix(n))
        // 繁琐设置
//        let mid = s.index(s.startIndex, offsetBy: n)
//        return String(s[mid..<s.endIndex] + s[s.startIndex..<mid])
        
        // 效率最低
        var array = Array(s)
        let count = array.count

        //! 往左移动 相当于 右移
        let k = count - n
        var start = 0
        var removeCount = 0

        while removeCount < count {

            var currentIndex = start
            var prev = array[start]

            repeat {
                let nextIndex = (currentIndex+k) % count
                let temp = array[nextIndex]

                array[nextIndex] = prev
                prev = temp
                currentIndex = nextIndex
                removeCount += 1

            } while start != currentIndex
            start += 1
        }
        return String(array)
    }

    /*
     415. 字符串相加
     https://leetcode-cn.com/problems/add-strings/
     */
    
    func addStrings(_ num1: String, _ num2: String) -> String {
        var result = ""
        let num1Chars = [Character](num1)
        let num2Chars = [Character](num2)
        var (i, j) = (num1.count - 1, num2.count - 1)
        var overflow = false
        let zeroASC = Character("0").asciiValue!
        while i >= 0 || j >= 0 {
            let n1 = i >= 0 ? num1Chars[i].asciiValue! - zeroASC : 0
            let n2 = j >= 0 ? num2Chars[j].asciiValue! - zeroASC : 0
            let sum = n1 + n2 + (overflow ? 1 : 0)
            overflow = sum > 9
            result = "\(sum % 10)" + result
            j -= 1
            i -= 1
        }
        if overflow {
            result = "1" + result
        }
        return result
    }
}

var res = [String]()
var path = String()

// medium
extension KuaishouViewController {
    
    /*
     1295 · 质因数统计
     */
    
    func countPrimeNum(_ n: Int) -> Int {
        // 动态规划（f（i * j） = f(i) + f(j)）
        var dp = [Int](repeating: 0, count: n + 1)
        for i in 2...n {
            // 质因数至少有一个
            dp[i] = 1
            for j in 2...i where i % j == 0 {
                dp[i] = dp[i / j] + dp[j]
                break
            }
        }
        return dp.reduce(0, +)
        
        // 暴力求解
        var result = 0
        for i in 2...n {
            result += getPrimeNum(i).count
        }
        return result
    }
    
    func getPrimeNum(_ n: Int) -> [Int] {
        if n == 2 {
            return [2]
        }
        var list: [Int] = []
        var m = 2
        var n = n
        while n >= m {
            if n % m == 0 {
                list.append(m)
                n = n / m
            } else {
                m += 1
            }
        }
        return list
    }
    
    /*m
     面试题 08.09. 括号
     https://leetcode-cn.com/problems/bracket-lcci/
     */

    func generateParenthesis(_ n: Int) -> [String] {
        if n <= 0  { return [] }
        backtrack(0, 0, n, "")
        return res
    }

    func backtrack(_ left: Int, _ right: Int, _ max: Int, _ curentString: String) {
        // terminator
        if left == max, right == max {
            res.append(curentString)
            return
        }
        // process locgic
        if left < max {
            backtrack(left + 1, right, max, curentString + "(")
        }
        if left > right {
            backtrack(left, right + 1, max, curentString + ")")
        }
        // recursive
        
        // reverse states

    }
    
    /*
     面试题 08.04. 幂集
     https://leetcode-cn.com/problems/power-set-lcci/
     */
    
    func subsets(_ nums: [Int]) -> [[Int]] {
        
        // 方法一：依次放入结果集中
        
//        var result: [[Int]] = [[]]
//        for num in nums {
//            for list in result {
//                var list = list
//                list.append(num)
//                result.append(list)
//            }
//        }
//        return result
//
        // 方法二：位运算
        /*
         [0，0，0] -> 0
         [0，0，1] -> 1
         [0，1，0] -> 2
         [0，1，1] -> 3
         [1，0，0] -> 4
         [1，0，1] -> 5
         [1，1，0] -> 6
         [1，1，1] -> 7
         */
        var result:[[Int]] = []
        // 2^3
        let count = 1 << nums.count
        for index in 0..<count {
            var list: [Int] = []
            for (j, num) in nums.enumerated() {
                if index >> j & 1 == 1 {
                    list.append(num)
                }
            }
            result.append(list)
        }
        return result
        
    }
    /*
     剑指 Offer 64. 求1+2+…+n
     
     https://leetcode-cn.com/problems/qiu-12n-lcof/
     
     */
    
    func sumNums(_ n: Int) -> Int {
        // 递归
        var sum = n
        n > 0 && { sum += sumNums(n - 1); return true }()
        return sum
        // 效率高
//        return (n * (n + 1)) >> 1
        // 效率贼低
        // return Array(1...n).reduce(0, +)
    }
    /*
     最长回文子串
     https://leetcode-cn.com/problems/longest-palindromic-substring/
     */
    
    func longestPalindrome(_ s: String) -> String {
        let count = s.count
        let stringArray = Array(s)
        var dp = Array(repeating: Array(repeating: false, count: count), count: count)
        var maxLength = 1
        var begin = 0
        
        for j in 0..<count {
            for i in 0 ..< j {
                if stringArray[i] != stringArray[j] {
                    dp[i][j] = false
                    continue
                }
                if (j - i <= 2) || dp[i + 1][j - 1] {
                    dp[i][j] = true
                    if j - i >= maxLength {
                        begin = i
                    }
                    maxLength = max(maxLength, j - i + 1)
                }
            }
        }
        return String(stringArray[begin..<(begin + maxLength)])
        
        
        /*
         for i in 0 ... j {
             if i == j { // 对角线无参考意义
                 dp[i][j] = true
                 continue
             }
         
         */
//        let strArr = Array(s)
//        let n = strArr.count
//        var dp = Array(repeating: Array(repeating: false, count: n), count: n)
//        var maxLenth = 1
//        var start = 0
//        var end = 0
//        for j in 0 ..< n {
//            for i in 0 ..< j + 1 {
//                if i == j {
//                    dp[i][j] = true
//                    continue
//                }
//                if strArr[i] != strArr[j] {
//                    dp[i][j] = false
//                    continue
//                }
//                if strArr[i] == strArr[j], (j - i <= 2) || dp[i + 1][j - 1]  {
//                    dp[i][j] = true
//                    if j - i >= maxLenth {
//                        start = i
//                        end = j
//                    }
//                    maxLenth = max(maxLenth, j - i + 1)
//                }
//            }
//        }
//        return String(strArr[start..<end + 1])
        
    }
    
    /*
     比较版本号
     https://leetcode-cn.com/problems/compare-version-numbers/
     */
    func compareVersion(_ version1: String, _ version2: String) -> Int {
        let v1Segments = version1.split(separator: ".")
        let v2Segments = version2.split(separator: ".")
        let v1Count = v1Segments.count
        let v2Count = v2Segments.count
        let maxCount = max(v2Count, v1Count)
        for i in 0..<maxCount {
            let v1ModifyNo = i < v1Count ? Int(v1Segments[i])! : 0
            let v2ModifyNo = i < v2Count ? Int(v2Segments[i])! : 0
            if v1ModifyNo > v2ModifyNo {
                return 1
            } else if v1ModifyNo < v2ModifyNo {
                return -1
            }
        }
        return 0
    }
}

// hard
extension KuaishouViewController {
    
}


















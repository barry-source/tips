//
//  LCHasCycleViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/24.
//

import UIKit

class LCHasCycleViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        var (head, tail) = createList1([3,2,0,-4, 8])
//        tail?.next = head?.next
        
        print(test(head))
    }
    
    /*
     快慢指针求解
     执行用时：64 ms, 在所有 Swift 提交中击败了57.46%的用户
     内存消耗：15.2 MB, 在所有 Swift 提交中击败了5.42%的用户
     */
    func hasCycle(_ head: ListNode?) -> Bool {
        if head == nil || head?.next == nil {
            return false
        }
        var fast: ListNode? = head?.next
        var slow: ListNode? = head
        while fast != nil && slow != nil {
            if fast === slow {
                print(fast?.val)
                return true
            }
            (fast, slow) = (fast?.next?.next, slow?.next)
        }
        return false
    }
    
    /*
     hash存储求解 val不可重复
     执行用时：64 ms, 在所有 Swift 提交中击败了57.46%的用户
     内存消耗：15.2 MB, 在所有 Swift 提交中击败了5.42%的用户
     */
    func hasCycle3(_ head: ListNode?) -> Bool {
        var head = head
        var hashTable: [ListNode: Int] = [:]
        while let c = head {
            if hashTable[c] != nil {
                return true
            } else {
                hashTable[c] = c.val
            }
            head = head?.next
        }
//        var hashTable: [Int: Int] = [:]
//        while let c = head {
//            if let val = hashTable[c.val], val == c.next?.val {
//                return true
//            } else if let n = c.next {
//                hashTable[c.val] = n.val
//            }
//            head = head?.next
//        }
        return false
    }
    
    // 数组超时(数据可以重复)
    func hasCycle2(_ head: ListNode?) -> Bool {
        if head == nil || head?.next == nil {
            return false
        }
        var head = head
        var tempListNodeArray: [ListNode] = []
        while head != nil {
            let result = tempListNodeArray.contains { $0 === head }
            if result {
                return true
            }
//            for e in tempListNodeArray {
//                if e === head {
//                    return true
//                }
//            }
            tempListNodeArray.append(head!)
            head = head?.next
        }
        return false
    }

}

extension LCHasCycleViewController {
    func test(_ head: ListNode?) -> Bool {
        if head == nil || head?.next == nil {
            return false
        }
        
        var slow = head
        var fast = head?.next
        while slow != nil && fast != nil {
            if slow == fast {
                return true
            }
            slow = slow?.next
            fast = fast?.next?.next
        }
        
        return false
    }
}

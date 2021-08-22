//
//  LCSwapParisViewController.swift
//  Leetcode
//
//  Created by TSC on 2020/12/23.
//

import UIKit

class LCSwapParisViewController: LCLinkBaseViewController {


    override func viewDidLoad() {
        super.viewDidLoad()
//        var array = [1, 2, 3]
        let array = [1, 2, 3, 1]
        
        let node = createList1(array)
        printList(swapPairs(node.0))
    }
    
    /*
     循环求解
     执行用时：8 ms, 在所有 Swift 提交中击败了41.83%的用户
     内存消耗：13.3 MB, 在所有 Swift 提交中击败了48.28%的用户
     */
    
    func swapPairs(_ head: ListNode?) -> ListNode? {
        if head == nil || head?.next == nil {
            return head
        }
        var dummyHead: ListNode? = ListNode(-1)
        dummyHead?.next = head
        
        var finalHead: ListNode?

        while dummyHead != nil {
            let first = dummyHead?.next
            let second = dummyHead?.next?.next
            let third = dummyHead?.next?.next?.next
            if second == nil { break }
            first?.next = third
            second?.next = first
            dummyHead?.next = second
            dummyHead = first
            if finalHead == nil {
                finalHead = second
            }
        }
        return finalHead
    }

    /*
     递归求解
     执行用时：4 ms, 在所有 Swift 提交中击败了97.69%的用户
     内存消耗：13.6 MB, 在所有 Swift 提交中击败了17.44%的用户
     */
    
//    func swapPairs(_ head: ListNode?) -> ListNode? {
//        if head == nil || head?.next == nil {
//            return head
//        }
//        let next = head?.next
//        head?.next = swapPairs(next?.next)
//        next?.next = head
//        return next
//    }

}

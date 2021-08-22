//
//  ByteDanceViewController.swift
//  Leetcode
//
//  Created by tongshichao on 2021/8/10.
//

import UIKit

class ByteDanceViewController: LCLinkBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let header = createList([1,2,3,4,5])
        reorderList(header)
        printList(header)
    }
    

    // https://leetcode-cn.com/problems/add-two-numbers/solution/liang-shu-xiang-jia-by-leetcode-solution/
    // 两数相加
    func addTwoNumbers(_ l1: ListNode?, _ l2: ListNode?) -> ListNode? {
        if l1 == nil { return l2 }
        if l2 == nil { return l1 }
        var l1 = l1, l2 = l2, finalHeader = ListNode(0)
        var header: ListNode? = finalHeader
        
        var overFlow = false // 进位标识
        while l1 != nil || l2 != nil || overFlow {
            let (num1, num2) = (l1?.val ?? 0, l2?.val ?? 0)
            let sum = num1 + num2 + (overFlow ? 1 : 0)
            overFlow = sum > 9
            header?.next = ListNode(sum % 10)
            header = header?.next
            (l1, l2) = (l1?.next, l2?.next)
        }
        return finalHeader.next
    }
    
    // 143. 重排链表
    // https://leetcode-cn.com/problems/reorder-list/
    
    func reorderList(_ head: ListNode?) {
        if head == nil || head!.next == nil { return }
        
        //快慢指针寻找中间节点
        var slow = head, fast = head
        while fast?.next != nil && fast?.next?.next != nil  {
            slow = slow?.next
            fast = fast?.next?.next
        }
        var second = slow?.next
        slow?.next = nil
        
        //后半段反转
        var pre: ListNode?
        while second != nil {
            let next = second?.next
            second?.next = pre
            pre = second
            second = next
        }
        second = pre
        
        //拼接
        let dummy = ListNode(0)
        var current = dummy
        var first = head
        
        while second != nil {
            current.next  = first
            
            let next = first?.next
            first?.next = second
            first = next

            current = second!
            second = second?.next
        }
        
        current.next = first // 奇数时first还有一个，偶数时是nil（是nil时也不影响）
        dummy.next = nil //
    }

}

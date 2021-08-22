//
//  PreviewModel.swift
//  Leetcode
//
//  Created by TSC on 2020/12/1.
//

import UIKit

struct PreviewModel: Codable {
    var title: String = ""
    var desc: String = ""
    var imageName: String?
    var timeComplexity: String = ""
    var cosumedTime: String = ""
    var occupiedSpace: String = ""
    
    var imageSize: CGSize = .zero
    var cellHeight: CGFloat = 0

    enum CodingKeys: String, CodingKey {
        case title
        case imageName
        case timeComplexity
        case cosumedTime
        case occupiedSpace
    }
} 

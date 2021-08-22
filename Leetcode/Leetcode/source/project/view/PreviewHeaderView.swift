//
//  PreviewHeaderView.swift
//  Leetcode
//
//  Created by TSC on 2020/12/1.
//

import UIKit

class PreviewHeaderView: UITableViewHeaderFooterView {

    var model: PreviewModel? {
        didSet {
            guard let model = model else { return }
            titleLabel.text = model.title
            let desc = "时间复杂度：" + model.timeComplexity + "\n" + "执行用时：" + model.cosumedTime + "\n" + "内存消耗：" + model.occupiedSpace
            let attributedString = NSMutableAttributedString(string: desc)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 5
            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))
            
            var stringOneRegex = try? NSRegularExpression(pattern: "执行用时：", options: [])
            var stringOneMatches = stringOneRegex?.matches(in: desc, options: [], range: NSMakeRange(0, attributedString.length))
            if let stringOneMatches = stringOneMatches {
                for stringOneMatch in stringOneMatches {
                    let wordRange = stringOneMatch.range(at: 0)
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(red: 0x21 / 255.0, green: 0x24 / 255.0, blue: 0x24 / 255.0, alpha: 1), range: wordRange)
                    attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 20, weight: .semibold), range: wordRange)
                }
            }
            
            stringOneRegex = try? NSRegularExpression(pattern: "内存消耗：", options: [])
            stringOneMatches = stringOneRegex?.matches(in: desc, options: [], range: NSMakeRange(0, attributedString.length))
            if let stringOneMatches = stringOneMatches {
                for stringOneMatch in stringOneMatches {
                    let wordRange = stringOneMatch.range(at: 0)
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(red: 0x21 / 255.0, green: 0x24 / 255.0, blue: 0x24 / 255.0, alpha: 1), range: wordRange)
                    attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 20, weight: .semibold), range: wordRange)
                }
            }
            
            stringOneRegex = try? NSRegularExpression(pattern: "时间复杂度：", options: [])
            stringOneMatches = stringOneRegex?.matches(in: desc, options: [], range: NSMakeRange(0, attributedString.length))
            if let stringOneMatches = stringOneMatches {
                for stringOneMatch in stringOneMatches {
                    let wordRange = stringOneMatch.range(at: 0)
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor(red: 0x21 / 255.0, green: 0x24 / 255.0, blue: 0x24 / 255.0, alpha: 1), range: wordRange)
                    attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont.systemFont(ofSize: 20, weight: .semibold), range: wordRange)
                }
            }
            
            descLabel.attributedText = attributedString
            
        }
    }
    
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor(red: 0xf7 / 255.0, green: 0xf8 / 255.0, blue: 0xfa / 255.0, alpha: 1)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.top.trailing.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
            make.bottom.equalTo(descLabel.snp.top).offset(-10)
        }
        descLabel.snp.makeConstraints { (make) in
            make.left.bottom.trailing.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .semibold)
        label.numberOfLines = 0
        label.textColor = UIColor(red: 0x21 / 255.0, green: 0x24 / 255.0, blue: 0x24 / 255.0, alpha: 1)
        return label
    }()
    
    lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = UIColor(red: 0x78 / 255.0, green: 0x7c / 255.0, blue: 0x78 / 255.0, alpha: 1)
        return label
    }()
    
}

fileprivate extension UILabel {
    func appendString(string: String, attrs: [NSAttributedString.Key: Any]) {
        let attrString: NSMutableAttributedString = NSMutableAttributedString()
        if let attributedText = attributedText {
            attrString.append(attributedText)
        }
        let appendString = NSMutableAttributedString(string: string, attributes:attrs)
        attrString.append(appendString)
        attributedText = attrString
    }
}

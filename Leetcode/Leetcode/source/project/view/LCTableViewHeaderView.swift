//
//  LCTableViewHeaderView.swift
//  Leetcode
//
//  Created by TSC on 2020/11/30.
//

import UIKit
import SnapKit

class LCTableViewHeaderView: UITableViewHeaderFooterView {

    var model: SectionModel? {
        didSet {
            titleLabel.text = model?.title
            circleView.image = UIImage(named: "green")
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // MARK: - UI
    func setupUI() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.addSubview(titleLabel)
        contentView.addSubview(circleView)
        
        circleView.snp.makeConstraints { (maker) in
            maker.left.equalTo(20)
            maker.size.equalTo(CGSize(width: 6, height: 6))
            maker.centerY.equalTo(titleLabel)
        }
        
        titleLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(circleView.snp.right).offset(7)
            maker.top.equalTo(30)
            maker.bottom.equalTo(-21)
        }
    }
    
    // MARK: - Lazy load
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private lazy var circleView: UIImageView = {
        let view = UIImageView()
        return view
    }()

}

//
//  LCTableViewCell.swift
//  Leetcode
//
//  Created by TSC on 2020/11/30.
//

import UIKit

class LCTableViewCell: UITableViewCell {

    var data: CellModel? {
        didSet {
            guard let data = data else { return }
            titleLabel.text = data.title
            coverLayer.setNeedsLayout()
            coverLayer.layoutSublayers()
        }
    }
    
    // MARK: - Init & Deinit
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - lifeCircle
    override func layoutSubviews() {
        super.layoutSubviews()
        lineView.isHidden = false
        coverLayer.frame = CGRect(x: 0, y: 0, width: contentView.bounds.size.width - 40, height: contentView.bounds.size.height)
        guard let data = data else { return }
        var corner: UIRectCorner = []
        if data.first && data.last {
            corner = .allCorners
        } else if data.first {
            corner = [.topLeft, .topRight]
        } else if data.last {
            corner = [.bottomLeft, .bottomRight]
        }
        let path = UIBezierPath(roundedRect: coverLayer.bounds, byRoundingCorners: corner, cornerRadii: CGSize(width: 25, height: 25))
        coverLayer.path = path.cgPath
    }
    
    // MARK: - UI
    func setupUI() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(pushImageView)
        containerView.addSubview(lineView)
        containerView.layer.insertSublayer(coverLayer, at: 0)
        
        containerView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20))
        }
        
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(20)
            make.bottom.equalTo(-20)
            make.left.equalTo(15)
            make.right.lessThanOrEqualTo(pushImageView.snp.left).offset(-25)
        }
        
        pushImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 14, height: 14))
            make.right.equalTo(-13)
            make.centerY.equalTo(titleLabel)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.left.equalTo(containerView).offset(15)
            make.height.equalTo(1)
            make.right.equalTo(containerView)
            make.bottom.equalTo(containerView)
        }
    }
    
    // MARK: - Lazy load
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.insertSublayer(coverLayer, at: 0)
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    private lazy var pushImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "arrow"))
        return imageView
    }()
    
    lazy var coverLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.white.cgColor
        return layer
    }()
    
    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0xf6 / 255.0, green: 0xf6 / 255.0, blue: 0xfc / 255.0, alpha: 1)
        return view
    }()

}


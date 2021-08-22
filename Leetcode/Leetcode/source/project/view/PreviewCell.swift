//
//  PreviewCell.swift
//  Leetcode
//
//  Created by TSC on 2020/12/1.
//

import UIKit

class PreviewCell: UITableViewCell {

    var model: PreviewModel? {
        didSet {
            guard let model = model else { return }
            if let imageName = model.imageName {
                fullImageView.image = UIImage(named: imageName)
            }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(fullImageView)
        selectionStyle = .none
        fullImageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    private lazy var fullImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
}

//
//  SearchTableViewCell.swift
//  MapText
//
//  Created by HUA on 2017/3/20.
//  Copyright © 2017年 HUA. All rights reserved.
//

import UIKit
import SnapKit
class SearchTableViewCell: UITableViewCell {
   
    var title  = UILabel()
    var address  = UILabel()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initSubView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func initSubView(){
        self.backgroundColor = UIColor.white
    
        self.addSubview(title)
        title.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(10)
            make.right.equalTo(self.snp.right).offset(-10)
            make.top.equalTo(self.snp.top).offset(5)
            make.height.equalTo(20)
        }
     title.font = UIFont.systemFont(ofSize: 15)
        self.addSubview(address)
        address.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(10)
            make.right.equalTo(self.snp.right).offset(-10)
            make.top.equalTo(title.snp.bottom).offset(2)
            make.height.equalTo(20)
        }
        address.font = UIFont.systemFont(ofSize: 12)
        address.textColor = UIColor.init(colorLiteralRed: 180/255.0, green: 180/255.0, blue: 180/255.0, alpha: 1)
        let line = UIImageView()
        line.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 244/255.0, blue: 240/255.0, alpha: 1)
        self.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left)
            make.right.equalTo(self.snp.right)
            make.bottom.equalTo(self.snp.bottom)
            make.height.equalTo(1)
        }
    }
    func setModel(model:SearchModel){
       
        self.title.text = model.name
        self.address.text = model.address
    }
}

//
//  MultiroutePlanView.swift
//  MapText
//
//  Created by HUA on 2017/3/22.
//  Copyright © 2017年 HUA. All rights reserved.
//

import UIKit
import SnapKit
class MultiroutePlanView: UIView {
    var comfirmBtn=UIButton()
    var array : [MultiRoutePlanModel]!
    init(frame:CGRect,array:Array<Any>) {
   super.init(frame: frame)
        self.array = array as! [MultiRoutePlanModel]
        initSubView()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
      func initSubView(){
        self.backgroundColor = UIColor.white
        self.addSubview(comfirmBtn)
        comfirmBtn.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(10)
            make.right.equalTo(self.snp.right).offset(-10)
            make.bottom.equalTo(self.snp.bottom).offset(-10)
            make.height.equalTo(40)
        }
        comfirmBtn.setTitle("导航", for: .normal)
        comfirmBtn.backgroundColor = UIColor.init(red: 49/255.0, green: 126/255.0, blue: 253/255.0, alpha: 1)
     
        for index in 0..<array.count{
            let selectView = UIView()
            self.addSubview(selectView)
            selectView.snp.makeConstraints({ (make) in
               make.left.equalTo(self).offset(CGFloat(index) * UIScreen.main.bounds.width/CGFloat(array.count))
                make.top.equalTo(self)
                make.width.equalTo( UIScreen.main.bounds.width/CGFloat(array.count))
                make.height.equalTo(100)
            })
            selectView.backgroundColor = UIColor.white
            
            let time = UILabel()
            selectView.addSubview(time)
            time.snp.makeConstraints({ (make) in
                make.left.right.equalTo(selectView)
                make.height.equalTo(30)
                make.top.equalTo(self).offset(30)
            })
            let model = array[index]
            time.text = "\(model.routeTime!)"
            time.font = UIFont.systemFont(ofSize: 20, weight: 1)
            time.textAlignment = .center

            let routeLength = UILabel()
            selectView.addSubview(routeLength)
            routeLength.snp.makeConstraints({ (make) in
                make.left.right.equalTo(selectView)
                make.height.equalTo(30)
                make.top.equalTo(self).offset(70)
            })
            routeLength.text = "\(model.routeStrategy?.rawValue)"
            routeLength.font = UIFont.systemFont(ofSize: 13)
            routeLength.textAlignment = .center
      
            
        }
        
        
    }
}

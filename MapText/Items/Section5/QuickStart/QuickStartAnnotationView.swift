//
//  QuickStartAnnotationView.swift
//  officialDemoNavi
//
//  Created by liubo on 10/14/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit

private class NaviButton: UIButton {
    
    private let carImageView = UIImageView(image: UIImage(named: "navi")!)
    private let naviLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        configSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configSubviews() {
        setBackgroundImage(UIImage(named: "naviBackgroundNormal")!, for: .normal)
        setBackgroundImage(UIImage(named: "naviBackgroundHighlighted")!, for: .selected)
        
        addSubview(carImageView)
        
        naviLabel.text = "导航"
        naviLabel.font = naviLabel.font.withSize(9)
        naviLabel.textColor = UIColor.white
        naviLabel.sizeToFit()
        
        addSubview(naviLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        carImageView.center = CGPoint(x: frame.midX, y: (superview?.frame.midY)! - carImageView.frame.height * (0.5 + 0.1))
        naviLabel.center = CGPoint(x: frame.midX, y: (superview?.frame.midY)! + carImageView.frame.height * (0.5 + 0.1))
    }
}

class QuickStartAnnotationView: MAPinAnnotationView {

    override init!(annotation: MAAnnotation!, reuseIdentifier: String!) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        let naviButton = NaviButton(frame: CGRect(x: 0, y: 0, width: 44, height: 74))
        
        leftCalloutAccessoryView = naviButton
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

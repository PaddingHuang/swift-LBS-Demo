//
//  GPSAnn.swift
//  MapText
//
//  Created by HUA on 2017/3/28.
//  Copyright © 2017年 HUA. All rights reserved.
//

import UIKit
enum KindsTypes {
    
    case oil
    case bank
    case stop
    
}
class KindsPointAnnotation:  MAPointAnnotation {
    var kindsTypes : KindsTypes?
    var gpsModel: GPSModel?
}


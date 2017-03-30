//
//  MultiRoutePlanModel.swift
//  MapText
//
//  Created by HUA on 2017/3/23.
//  Copyright © 2017年 HUA. All rights reserved.
//

import UIKit

class MultiRoutePlanModel: NSObject {
    //ID
    var  aNumber : Int?
    //距离.米
    var routeLength : Int?
    //预估时间。秒

    var routeTime : Int?
    //红绿灯个数
    var routeTrafficLightCount : Int?
    
    var   routeStrategy : AMapNaviDrivingStrategy?
}

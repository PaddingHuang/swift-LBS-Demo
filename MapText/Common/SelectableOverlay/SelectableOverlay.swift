//
//  SelectableOverlay.swift
//  officialDemoNavi
//
//  Created by liubo on 10/11/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import Foundation

class SelectableOverlay: NSObject, MAOverlay {
    
    var routeID: Int = 0
    var selected = false
    var selectedColor = UIColor(red: 0.05, green: 0.39, blue: 0.9, alpha: 0.8)
    var reguarColor = UIColor(red: 0.5, green: 0.6, blue: 0.9, alpha: 0.8)
    
    var overlay: MAOverlay
    
    init(aOverlay: MAOverlay) {
        overlay = aOverlay
        super.init()
    }
    
    var coordinate: CLLocationCoordinate2D {
        return overlay.coordinate
    }
    
    var boundingMapRect: MAMapRect {
        return overlay.boundingMapRect
    }
    
}

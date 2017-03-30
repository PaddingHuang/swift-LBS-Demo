//
//  TextViewController.swift
//  MapText
//
//  Created by HUA on 2017/3/24.
//  Copyright © 2017年 HUA. All rights reserved.
//

import UIKit

class TextViewController: UIViewController ,AMapNaviDriveManagerDelegate{
var driveManager: AMapNaviDriveManager?
    override func viewDidLoad() {
        super.viewDidLoad()
        driveManager = AMapNaviDriveManager.init()
        driveManager?.delegate = self
        
        driveManager?.allowsBackgroundLocationUpdates = true
        driveManager?.pausesLocationUpdatesAutomatically = false
        // Do any additional setup after loading the view.
        let backBtn = UIButton()
        self.view.addSubview(backBtn)

        backBtn.frame = CGRect.init(x: 10, y: 30, width: 30, height: 30)
        backBtn.backgroundColor = UIColor.white
        backBtn.setImage(UIImage.init(named: "map_icon_out"), for: .normal)
        backBtn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        
        
    }
    
    func backBtnClick(){
        //停止导航
        //        driveManager.stopNavi()
        //        SpeechSynthesizer.Shared.stopSpeak()
        //     _ = self.navigationController?.popViewController(animated: true)
        
        self.dismiss(animated: true) {
            
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK: - AMapNaviDriveManager Delegate
    
    func driveManager(_ driveManager: AMapNaviDriveManager, error: Error) {
        let error = error as NSError
        NSLog("error:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func driveManager(onCalculateRouteSuccess driveManager: AMapNaviDriveManager) {
        NSLog("CalculateRouteSuccess")
        
      
    }

    
   
}

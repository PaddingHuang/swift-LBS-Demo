//
//  HUDNaviViewController.swift
//  officialDemoNavi
//
//  Created by liubo on 10/11/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit

class HUDNaviViewController: UIViewController, AMapNaviDriveManagerDelegate, AMapNaviHUDViewDelegate {
    
    var hudView: AMapNaviHUDView!
    var driveManager: AMapNaviDriveManager!
    
    //为了方便展示驾车多路径规划，选择了固定的起终点
    let startPoint = AMapNaviPoint.location(withLatitude: 39.993135, longitude: 116.474175)!
    let endPoint = AMapNaviPoint.location(withLatitude: 39.908791, longitude: 116.321257)!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        initHUDView()
        initDriveManager()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = true
        navigationController?.isToolbarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        calculateRoute()
    }
    
    override func viewWillLayoutSubviews() {
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        if UIInterfaceOrientationIsPortrait(interfaceOrientation) {
            hudView.isLandscape = false
        }
        else if UIInterfaceOrientationIsLandscape(interfaceOrientation) {
            hudView.isLandscape = true
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Initalization
    
    func initHUDView() {
        hudView = AMapNaviHUDView(frame: view.bounds)
        hudView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hudView.delegate = self
        
        view.addSubview(hudView)
    }
    
    func initDriveManager() {
        driveManager = AMapNaviDriveManager()
        driveManager.delegate = self
        
        driveManager.allowsBackgroundLocationUpdates = true
        driveManager.pausesLocationUpdatesAutomatically = false
        
        //将hudView添加为导航数据的Representative，使其可以接收到导航诱导数据
        driveManager.addDataRepresentative(hudView)
    }
    
    //MARK: - Button Action
    
    func calculateRoute() {
        //进行路径规划
        driveManager.calculateDriveRoute(withStart: [startPoint],
                                         end: [endPoint],
                                         wayPoints: nil,
                                         drivingStrategy: .multipleAvoidCongestion)
    }
    
    //MARK: - AMapNaviHUDView Delegate
    
    func hudViewCloseButtonClicked(_ hudView: AMapNaviHUDView) {
        //停止导航
        driveManager.stopNavi()
        driveManager.removeDataRepresentative(hudView)
        
        //停止语音
        SpeechSynthesizer.Shared.stopSpeak()
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    //MARK: - AMapNaviDriveManager Delegate
    
    func driveManager(_ driveManager: AMapNaviDriveManager, error: Error) {
        let error = error as NSError
        NSLog("error:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func driveManager(onCalculateRouteSuccess driveManager: AMapNaviDriveManager) {
        NSLog("CalculateRouteSuccess")
        
        //算路成功后进行模拟导航
        self.driveManager.startEmulatorNavi()
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, onCalculateRouteFailure error: Error) {
        let error = error as NSError
        NSLog("CalculateRouteFailure:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, didStartNavi naviMode: AMapNaviMode) {
        NSLog("didStartNavi");
    }
    
    func driveManagerNeedRecalculateRoute(forYaw driveManager: AMapNaviDriveManager) {
        NSLog("needRecalculateRouteForYaw");
    }
    
    func driveManagerNeedRecalculateRoute(forTrafficJam driveManager: AMapNaviDriveManager) {
        NSLog("needRecalculateRouteForTrafficJam");
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, onArrivedWayPoint wayPointIndex: Int32) {
        NSLog("ArrivedWayPoint:\(wayPointIndex)");
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, playNaviSound soundString: String, soundStringType: AMapNaviSoundType) {
        NSLog("playNaviSoundString:{%d:%@}", soundStringType.rawValue, soundString);
        
        SpeechSynthesizer.Shared.speak(soundString)
    }
    
    func driveManagerDidEndEmulatorNavi(_ driveManager: AMapNaviDriveManager) {
        NSLog("didEndEmulatorNavi");
    }
    
    func driveManager(onArrivedDestination driveManager: AMapNaviDriveManager) {
        NSLog("onArrivedDestination");
    }

}

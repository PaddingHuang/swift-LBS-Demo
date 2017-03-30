//
//  GPSNaviViewController.swift
//  officialDemoNavi
//
//  Created by liubo on 10/11/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit

class GPSNaviViewController: UIViewController, AMapNaviDriveManagerDelegate, AMapNaviDriveViewDelegate, MoreMenuViewDelegate {

    var driveView: AMapNaviDriveView!
    var driveManager: AMapNaviDriveManager!
    
    //为了方便展示,选择了固定的起终点
    let startPoint = AMapNaviPoint.location(withLatitude: 39.993135, longitude: 116.474175)!
    let endPoint = AMapNaviPoint.location(withLatitude: 39.908791, longitude: 116.321257)!
    
    var moreMenu: MoreMenuView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        initDriveView()
        initDriveManager()
        initMoreMenu()
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
            driveView.isLandscape = false
        }
        else if UIInterfaceOrientationIsLandscape(interfaceOrientation) {
            driveView.isLandscape = true
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Initalization
    
    func initDriveView() {
        driveView = AMapNaviDriveView(frame: view.bounds)
        driveView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        driveView.delegate = self
        
        view.addSubview(driveView)
    }
    
    func initDriveManager() {
        driveManager = AMapNaviDriveManager()
        driveManager.delegate = self
        
        driveManager.allowsBackgroundLocationUpdates = true
        driveManager.pausesLocationUpdatesAutomatically = false
        
        //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
        driveManager.addDataRepresentative(driveView)
    }
    
    func initMoreMenu() {
        moreMenu = MoreMenuView(frame: view.bounds)
        moreMenu.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        moreMenu.delegate = self
    }
    
    //MARK: - Button Action
    
    func calculateRoute() {
        //进行路径规划
        driveManager.calculateDriveRoute(withStart: [startPoint],
                                         end: [endPoint],
                                         wayPoints: nil,
                                         drivingStrategy: .singleDefault)
    }
    
    //MARK: - AMapNaviDriveManager Delegate
    
    func driveManager(_ driveManager: AMapNaviDriveManager, error: Error) {
        let error = error as NSError
        NSLog("error:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func driveManager(onCalculateRouteSuccess driveManager: AMapNaviDriveManager) {
        NSLog("CalculateRouteSuccess")
        
        //算路成功后开始GPS导航
        driveManager.startGPSNavi()
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
    
    //MARK: - AMapNaviDriveViewDelegate
    
    func driveViewCloseButtonClicked(_ driveView: AMapNaviDriveView) {
        
        //停止导航
        driveManager.stopNavi()
        driveManager.removeDataRepresentative(driveView)
        
        //停止语音
        SpeechSynthesizer.Shared.stopSpeak()
        
        _ = navigationController?.popViewController(animated: true)
    }
    
    func driveViewMoreButtonClicked(_ driveView: AMapNaviDriveView) {
        
        //配置MoreMenu状态
        moreMenu.trackingMode = driveView.trackingMode
        moreMenu.showNightType = driveView.showStandardNightType
        
        moreMenu.frame = view.bounds
        view.addSubview(moreMenu)
    }
    
    func driveViewTrunIndicatorViewTapped(_ driveView: AMapNaviDriveView) {
        NSLog("TrunIndicatorViewTapped");
    }
    
    func driveView(_ driveView: AMapNaviDriveView, didChange showMode: AMapNaviDriveViewShowMode) {
        NSLog("didChangeShowMode:\(showMode)");
    }
    
    //MARK: - MoreMenu Delegate
    func moreMenuViewFinishButtonClicked() {
        moreMenu.removeFromSuperview()
    }
    
    func moreMenuViewNightTypeChange(to isShowNightType: Bool) {
        driveView.showStandardNightType = isShowNightType
    }
    
    func moreMenuViewTrackingModeChange(to trackingMode: AMapNaviViewTrackingMode) {
        driveView.trackingMode = trackingMode
    }
}

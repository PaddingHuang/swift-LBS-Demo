//
//  CustomTurnInfoViewController.swift
//  officialDemoNavi
//
//  Created by liubo on 10/14/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit

class CustomTurnInfoViewController: UIViewController, AMapNaviDriveManagerDelegate, AMapNaviDriveViewDelegate, AMapNaviDriveDataRepresentable {
    
    var driveView: AMapNaviDriveView!
    var driveManager: AMapNaviDriveManager!
    
    let startPoint = AMapNaviPoint.location(withLatitude: 39.993135, longitude: 116.474175)!
    let endPoint = AMapNaviPoint.location(withLatitude: 39.910267, longitude: 116.370888)!
    let wayPints = [AMapNaviPoint.location(withLatitude: 39.973135, longitude: 116.444175)!,
                    AMapNaviPoint.location(withLatitude: 39.987125, longitude: 116.353145)!]
    
    var turnRemainInfoLabel: UILabel!
    var roadInfoLabel: UILabel!
    var routeRemainInfoLabel: UILabel!
    var cameraInfoLabel: UILabel!

    deinit {
        driveManager.stopNavi()
        driveManager.removeDataRepresentative(driveView)
        driveManager.removeDataRepresentative(self)
        driveManager.delegate = nil
        
        driveView.removeFromSuperview()
        driveView.delegate = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        initDriveView()
        initDriveManager()
        configSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.isToolbarHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        calculateRoute()
    }
    
    // MARK: - Initalization
    
    func initDriveView() {
        driveView = AMapNaviDriveView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 400))
        driveView.delegate = self
        
        //将导航界面的界面元素进行隐藏，然后通过自定义的控件展示导航信息
        driveView.showUIElements = false
        
        view.addSubview(driveView)
    }
    
    func initDriveManager() {
        driveManager = AMapNaviDriveManager()
        driveManager.delegate = self
        
        //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
        driveManager.addDataRepresentative(driveView)
        
        //将当前VC添加为导航数据的Representative，使其可以接收到导航诱导数据
        driveManager.addDataRepresentative(self)
    }
    
    //MARK: - Route Plan
    
    func calculateRoute() {
        driveManager.calculateDriveRoute(withStart: [startPoint],
                                         end: [endPoint],
                                         wayPoints: wayPints,
                                         drivingStrategy: .singleDefault)
    }
    
    //MARK: - Subviews
    
    func configSubviews() {
        turnRemainInfoLabel = UILabel(frame: CGRect(x: 0, y: 410, width: view.bounds.width, height: 20))
        turnRemainInfoLabel.textAlignment = .center
        turnRemainInfoLabel.font = UIFont.systemFont(ofSize: 14)
        turnRemainInfoLabel.text = "转向剩余距离"
        view.addSubview(turnRemainInfoLabel)
        
        roadInfoLabel = UILabel(frame: CGRect(x: 0, y: 430, width: view.bounds.width, height: 20))
        roadInfoLabel.textAlignment = .center
        roadInfoLabel.font = UIFont.systemFont(ofSize: 14)
        roadInfoLabel.text = "道路信息"
        view.addSubview(roadInfoLabel)
        
        routeRemainInfoLabel = UILabel(frame: CGRect(x: 0, y: 450, width: view.bounds.width, height: 20))
        routeRemainInfoLabel.textAlignment = .center
        routeRemainInfoLabel.font = UIFont.systemFont(ofSize: 14)
        routeRemainInfoLabel.text = "道路剩余信息"
        view.addSubview(routeRemainInfoLabel)
        
        cameraInfoLabel = UILabel(frame: CGRect(x: 0, y: 470, width: view.bounds.width, height: 20))
        cameraInfoLabel.textAlignment = .center
        cameraInfoLabel.font = UIFont.systemFont(ofSize: 14)
        cameraInfoLabel.text = "电子眼信息"
        view.addSubview(cameraInfoLabel)
    }
    
    //MARK: - AMapNaviDriveDataRepresentable
    
    func driveManager(_ driveManager: AMapNaviDriveManager, update naviMode: AMapNaviMode) {
        NSLog("updateNaviMode:%d", naviMode.rawValue)
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, updateNaviRouteID naviRouteID: Int) {
        NSLog("updateNaviRouteID:%d", naviRouteID)
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, update naviRoute: AMapNaviRoute?) {
        NSLog("updateNaviRoute")
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, update naviInfo: AMapNaviInfo?) {
        guard let naviInfo = naviInfo else {
            return
        }
        
        //展示AMapNaviInfo类中的导航诱导信息，更多详细说明参考类 AMapNaviInfo 注释。
        
        //转向剩余距离
        let remainDis = normalizedRemainDistance(naviInfo.routeRemainDistance)
        turnRemainInfoLabel.text = String(format: "%@ 后，转向类型:%d", remainDis, naviInfo.iconType.rawValue)
        
        //道路信息
        roadInfoLabel.text = String(format: "从 %@ 进入 %@", naviInfo.currentRoadName, naviInfo.nextRoadName)
        
        //路径剩余信息
        routeRemainInfoLabel.text = String(format: "剩余距离:%@ 剩余时间:%@", normalizedRemainDistance(naviInfo.routeRemainDistance), normalizedRemainTime(naviInfo.routeRemainTime))
        
        //距离最近的下个电子眼信息
        var cameraStr = "暂无"
        if naviInfo.cameraDistance > 0 {
            cameraStr = naviInfo.cameraType == 0 ? String(format: "测速(%d)", naviInfo.cameraLimitSpeed) : "监控"
        }
        cameraInfoLabel.text = String(format: "电子眼信息:%@", cameraStr)
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, update naviLocation: AMapNaviLocation?) {
        NSLog("updateNaviLocation")
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, showCross crossImage: UIImage) {
        NSLog("showCrossImage")
    }
    
    func driveManagerHideCrossImage(_ driveManager: AMapNaviDriveManager) {
        NSLog("hideCrossImage")
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, showLaneBackInfo laneBackInfo: String, laneSelectInfo: String) {
        NSLog("showLaneInfo")
    }
    
    func driveManagerHideLaneInfo(_ driveManager: AMapNaviDriveManager) {
        NSLog("hideLaneInfo")
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, updateTrafficStatus trafficStatus: [AMapNaviTrafficStatus]?) {
        NSLog("updateTrafficStatus")
    }
    
    //MARK: - AMapNaviDriveManager Delegate
    
    func driveManager(_ driveManager: AMapNaviDriveManager, error: Error) {
        let error = error as NSError
        NSLog("error:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func driveManager(onCalculateRouteSuccess driveManager: AMapNaviDriveManager) {
        NSLog("CalculateRouteSuccess")
        
        driveManager.startEmulatorNavi()
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
    }
    
    func driveManagerDidEndEmulatorNavi(_ driveManager: AMapNaviDriveManager) {
        NSLog("didEndEmulatorNavi");
    }
    
    func driveManager(onArrivedDestination driveManager: AMapNaviDriveManager) {
        NSLog("onArrivedDestination");
    }
    
    //MARK: - AMapNaviDriveViewDelegate
    
    func driveView(_ driveView: AMapNaviDriveView, didChange showMode: AMapNaviDriveViewShowMode) {
        NSLog("didChangeShowMode:\(showMode)");
    }
    
    //MARK: - Utility
    
    func normalizedRemainDistance(_ remainDistance: Int) -> String {
        guard remainDistance >= 0 else {
            return ""
        }
        
        if remainDistance >= 1000 {
            var kiloMeter = Double(remainDistance) / 1000.0
            
            if remainDistance % 1000 >= 1000 {
                kiloMeter -= 0.05
                return String(format: "%.1f公里", kiloMeter)
            }
            else {
                return String(format: "%.0f公里", kiloMeter)
            }
        }
        else {
            return String(format: "%d米", remainDistance)
        }
    }
    
    func normalizedRemainTime(_ remainTime: Int) -> String {
        guard remainTime >= 0 else {
            return ""
        }
        
        if remainTime < 60 {
            return "< 1分钟"
        }
        else if remainTime >= 60 && remainTime < 60*60 {
            return String(format: "%d分钟", remainTime/60)
        }
        else {
            let hours = remainTime / 60 / 60
            let minute = remainTime / 60 % 60
            
            if minute == 0 {
                return String(format: "%d小时", hours)
            }
            else {
                return String(format: "%d小时%d分钟", hours, minute)
            }
        }
    }

}

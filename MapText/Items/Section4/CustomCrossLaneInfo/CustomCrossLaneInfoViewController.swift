//
//  CustomCrossLaneInfoViewController.swift
//  officialDemoNavi
//
//  Created by liubo on 10/14/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit

class CustomCrossLaneInfoViewController: UIViewController, AMapNaviDriveManagerDelegate, AMapNaviDriveViewDelegate, AMapNaviDriveDataRepresentable {

    var driveView: AMapNaviDriveView!
    var driveManager: AMapNaviDriveManager!
    
    let startPoint = AMapNaviPoint.location(withLatitude: 39.993135, longitude: 116.474175)!
    let endPoint = AMapNaviPoint.location(withLatitude: 39.910267, longitude: 116.370888)!
    let wayPints = [AMapNaviPoint.location(withLatitude: 39.973135, longitude: 116.444175)!,
                    AMapNaviPoint.location(withLatitude: 39.987125, longitude: 116.353145)!]
    
    var laneInfoView = UIImageView()
    var crossImageView = UIImageView()
    
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
        laneInfoView.center = CGPoint(x: view.bounds.midX, y: 480)
        view.addSubview(laneInfoView)
        
        crossImageView.frame = CGRect(x: view.bounds.midX - 90, y: 300, width: 180, height: 140)
        view.addSubview(crossImageView)
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
        
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, update naviLocation: AMapNaviLocation?) {
        NSLog("updateNaviLocation")
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, showCross crossImage: UIImage) {
        NSLog("showCrossImage")
        
        //显示路口放大图
        crossImageView.image = crossImage
    }
    
    func driveManagerHideCrossImage(_ driveManager: AMapNaviDriveManager) {
        NSLog("hideCrossImage")
        
        //隐藏路口放大图
        crossImageView.image = nil
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, showLaneBackInfo laneBackInfo: String, laneSelectInfo: String) {
        NSLog("showLaneInfo")
        
        //根据车道信息生成车道信息Image
        if let laneInfoImage = CreateLaneInfoImageWithLaneInfo(laneBackInfo, laneSelectInfo) {
            //显示车道信息
            laneInfoView.image = laneInfoImage
            laneInfoView.bounds = CGRect(x: 0, y: 0, width: laneInfoImage.size.width, height: laneInfoImage.size.height)
        }
        else {
            laneInfoView.image = nil
        }
    }
    
    func driveManagerHideLaneInfo(_ driveManager: AMapNaviDriveManager) {
        NSLog("hideLaneInfo")
        
        //隐藏车道信息
        laneInfoView.image = nil
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

}

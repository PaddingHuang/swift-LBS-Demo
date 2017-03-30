//
//  CustomFunctionalButtonViewController.swift
//  officialDemoNavi
//
//  Created by liubo on 10/14/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit

class CustomFunctionalButtonViewController: UIViewController, AMapNaviDriveManagerDelegate, AMapNaviDriveViewDelegate {

    var driveView: AMapNaviDriveView!
    var driveManager: AMapNaviDriveManager!
    
    let startPoint = AMapNaviPoint.location(withLatitude: 39.993135, longitude: 116.474175)!
    let endPoint = AMapNaviPoint.location(withLatitude: 39.910267, longitude: 116.370888)!
    let wayPints = [AMapNaviPoint.location(withLatitude: 39.973135, longitude: 116.444175)!,
                    AMapNaviPoint.location(withLatitude: 39.987125, longitude: 116.353145)!]
    
    var showMode: UISegmentedControl!
    var trafficLayerButton: UIButton!
    var zoomInButton: UIButton!
    var zoomOutButton: UIButton!
    
    deinit {
        driveManager.stopNavi()
        driveManager.removeDataRepresentative(driveView)
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
        showMode = UISegmentedControl(items: ["锁车状态","全览状态","普通状态"])
        showMode.frame = CGRect(x: 10, y: 410, width: 200, height: 30)
        showMode.addTarget(self, action: #selector(self.showModeAction(sender:)), for: .valueChanged)
        showMode.selectedSegmentIndex = 0
        view.addSubview(showMode)
        
        trafficLayerButton = buttonForTitle("交通信息")
        trafficLayerButton.frame = CGRect(x: 10, y: 460, width: 80, height: 30)
        trafficLayerButton.addTarget(self, action: #selector(self.trafficLayerAction), for: .touchUpInside)
        view.addSubview(trafficLayerButton)
        
        zoomInButton = buttonForTitle("ZoomIn")
        zoomInButton.frame = CGRect(x: 100, y: 460, width: 80, height: 30)
        zoomInButton.addTarget(self, action: #selector(self.zoomInAction), for: .touchUpInside)
        view.addSubview(zoomInButton)
        
        zoomOutButton = buttonForTitle("ZoomOut")
        zoomOutButton.frame = CGRect(x: 190, y: 460, width: 80, height: 30)
        zoomOutButton.addTarget(self, action: #selector(self.zoomOutAction), for: .touchUpInside)
        view.addSubview(zoomOutButton)
    }
    
    private func buttonForTitle(_ title: String) -> UIButton {
        let reBtn = UIButton(type: .custom)
        
        reBtn.layer.borderColor = UIColor.lightGray.cgColor
        reBtn.layer.borderWidth = 1.0
        reBtn.layer.cornerRadius = 5
        
        reBtn.bounds = CGRect(x: 0, y: 0, width: 80, height: 30)
        reBtn.setTitle(title, for: .normal)
        reBtn.setTitleColor(UIColor.black, for: .normal)
        reBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        
        return reBtn
    }
    
    //MARK: - Button Action
    
    func trafficLayerAction() {
        //是否显示实时交通路况
        driveView.showTrafficLayer = !driveView.showTrafficLayer
    }
    
    func showModeAction(sender: UISegmentedControl) {
        //改变界面的显示模式
        switch sender.selectedSegmentIndex {
        case 0:
            driveView.showMode = .carPositionLocked
        case 1:
            driveView.showMode = .overview
        case 2:
            driveView.showMode = .normal
        default:
            break
        }
    }
    
    func zoomInAction() {
        //改变地图的zoomLevel，会进入非锁车状态
        driveView.mapZoomLevel = driveView.mapZoomLevel + 1
    }
    
    func zoomOutAction() {
        //改变地图的zoomLevel，会进入非锁车状态
        driveView.mapZoomLevel = driveView.mapZoomLevel - 1
    }
    
    //MARK: - AMapNaviDriveViewDelegate
    
    func driveView(_ driveView: AMapNaviDriveView, didChange showMode: AMapNaviDriveViewShowMode) {
        NSLog("didChangeShowMode:\(showMode)");
        
        //显示模式发生改变后的回调方法
        switch showMode {
        case .carPositionLocked:
            self.showMode.selectedSegmentIndex = 0
        case .overview:
            self.showMode.selectedSegmentIndex = 1
        case .normal:
            self.showMode.selectedSegmentIndex = 2
        }
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

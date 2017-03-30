//
//  GPSEmulatorViewController.swift
//  officialDemoNavi
//
//  Created by liubo on 10/11/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit

class GPSEmulatorViewController: UIViewController, AMapNaviDriveViewDelegate, AMapNaviDriveManagerDelegate, AMapNaviDriveDataRepresentable {
    
    var driveView: AMapNaviDriveView!
    var driveManager: AMapNaviDriveManager!
    
    //为了方便展示GPS模拟的结果，我们提前录制了一段GPS坐标，同时配合固定的两个点进行算路导航
    let startPoint = AMapNaviPoint.location(withLatitude: 39.993135, longitude: 116.474175)!
    let endPoint = AMapNaviPoint.location(withLatitude: 39.908791, longitude: 116.321257)!
    
    let gpsEmulator = GPSEmulator()

    deinit {
        driveManager.stopNavi()
        driveManager.removeDataRepresentative(driveView)
        
        SpeechSynthesizer.Shared.stopSpeak()
        
        gpsEmulator.stop()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        initToolBar()
        initDriveView()
        initDriveManager()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.isToolbarHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        calculateRoute()
    }
    
    // MARK: - Initalization
    
    func initDriveView() {
        driveView = AMapNaviDriveView(frame: UIEdgeInsetsInsetRect(view.bounds, UIEdgeInsetsMake(0, 0, 48, 0)))
        driveView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        driveView.delegate = self
        
        view.addSubview(driveView)
    }
    
    func initDriveManager() {
        driveManager = AMapNaviDriveManager()
        driveManager.delegate = self
        
        //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
        driveManager.addDataRepresentative(driveView)
    }
    
    func initToolBar() {
        let flexbleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        let switchSegmentedControl = UISegmentedControl(items: ["停止GPS模拟", "开始GPS模拟"])
        switchSegmentedControl.selectedSegmentIndex = 0
        switchSegmentedControl.addTarget(self, action: #selector(self.switchSegmentControlAction(sender:)), for: .valueChanged)
        
        let switchModeItem = UIBarButtonItem(customView: switchSegmentedControl)
        
        toolbarItems = [flexbleItem, switchModeItem, flexbleItem]
    }
    
    //MARK: - Segmented Control Action
    
    func switchSegmentControlAction(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            stopGPSEmulator()
        }
        else if sender.selectedSegmentIndex == 1 {
            startGPSEmulator()
        }
    }
    
    //MARK: - GPS Emulator
    
    //开始传入GPS模拟数据进行导航
    func startGPSEmulator() {
        guard gpsEmulator.isSimulating == false else {
            NSLog("GPSEmulator is already running")
            return
        }
        
        //开启使用外部GPS数据
        driveManager.enableExternalLocation = true
        
        //开始GPS导航
        driveManager.startGPSNavi()
        
        gpsEmulator.start { [weak self] (location, index, addedTime, stop) in
            guard let location = location else {
                return
            }
            
            //注意：需要使用当前时间作为时间戳
            let newLocation = CLLocation(coordinate: location.coordinate,
                                         altitude: location.altitude,
                                         horizontalAccuracy: location.horizontalAccuracy,
                                         verticalAccuracy: location.verticalAccuracy,
                                         course: location.course,
                                         speed: location.speed,
                                         timestamp: Date(timeIntervalSinceNow: 0))
            
            //传入GPS模拟数据
            self?.driveManager.setExternalLocation(newLocation, isAMapCoordinate: false)
            
            NSLog("SimGPS:{%f-%f-%f-%f}", location.coordinate.latitude, location.coordinate.longitude, location.speed, location.course)
        }
    }
    
    //停止传入GPS模拟数据
    func stopGPSEmulator() {
        gpsEmulator.stop()
        
        driveManager.stopNavi()
        
        driveManager.enableExternalLocation = false
    }
    
    //MARK: - Route Plan
    
    func calculateRoute() {
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
    
    func driveViewMoreButtonClicked(_ driveView: AMapNaviDriveView) {
        switch driveView.trackingMode {
        case .carNorth:
            self.driveView.trackingMode = .mapNorth
        case .mapNorth:
            self.driveView.trackingMode = .carNorth
        }
    }

}

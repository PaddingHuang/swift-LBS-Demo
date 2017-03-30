//
//  DetectedModeViewController.swift
//  officialDemoNavi
//
//  Created by liubo on 10/11/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit
import AudioToolbox

class DetectedModeViewController: UIViewController, AMapNaviDriveManagerDelegate, AMapNaviDriveDataRepresentable, MAMapViewDelegate {

    var mapView: MAMapView!
    var driveManager: AMapNaviDriveManager!
    
    var carAnnotation = MAPointAnnotation()
    
    deinit {
        driveManager.detectedMode = .none
        driveManager.removeDataRepresentative(self)
        SpeechSynthesizer.Shared.stopSpeak()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        initToolBar()
        initMapView()
        initDriveManager()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.isToolbarHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.addAnnotation(carAnnotation)
        
        //将当前VC添加为导航数据的Representative，使其可以接收到导航诱导数据
        driveManager.addDataRepresentative(self)
        
        //开启智能巡航模式
        driveManager.detectedMode = .cameraAndSpecialRoad
        
        notifyNeedDriving()
    }
    
    // MARK: - Initalization
    
    func initMapView() {
        mapView = MAMapView(frame: view.bounds)
        mapView.delegate = self
        view.addSubview(mapView)
    }
    
    func initDriveManager() {
        driveManager = AMapNaviDriveManager()
        driveManager.delegate = self
        
        driveManager.allowsBackgroundLocationUpdates = true
        driveManager.pausesLocationUpdatesAutomatically = false
    }
    
    func initToolBar() {
        let flexbleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        let detectedModeSegmentedControl = UISegmentedControl(items: ["关闭", "电子眼和特殊道路设施"])
        detectedModeSegmentedControl.selectedSegmentIndex = 1
        detectedModeSegmentedControl.addTarget(self, action: #selector(self.detectedModeAction(sender:)), for: .valueChanged)
        
        let detectedModeItem = UIBarButtonItem(customView: detectedModeSegmentedControl)
        
        toolbarItems = [flexbleItem, detectedModeItem, flexbleItem]
    }
    
    //MARK: - Segmented Control Action
    
    func detectedModeAction(sender: UISegmentedControl) {
        
        guard let selectedTitle = sender.titleForSegment(at: sender.selectedSegmentIndex) else {
            return
        }
        
        if selectedTitle == "关闭" {
            //停止语音
            SpeechSynthesizer.Shared.stopSpeak()
            
            driveManager.detectedMode = .none
        }
        else if selectedTitle == "电子眼和特殊道路设施" {
            //开启智能巡航模式
            driveManager.detectedMode = .cameraAndSpecialRoad
        }
        
        NSLog("DetectedMode:%d", driveManager.detectedMode.rawValue)
    }
    
    //MARK: - Utility
    
    func updateCarAnnotationCoordinate(_ coordinate: CLLocationCoordinate2D) {
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.carAnnotation.coordinate = coordinate
        }
        
        mapView.setCenter(coordinate, animated: true)
        mapView.setZoomLevel(17.1, animated: true)
    }
    
    func notifyNeedDriving() {
        let alert = UIAlertView(title: nil, message: "智能播报功能需要在驾车过程中体验~", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
    
    //MARK: - AMapNaviDriveDataRepresentable
    /*
     这里只需要关注巡航相关数据，更多数据更新回调参考 AMapNaviDriveDataRepresentable 。
     */
    func driveManager(_ driveManager: AMapNaviDriveManager, update naviLocation: AMapNaviLocation?) {
        guard let naviLocation = naviLocation else {
            return
        }
        
        updateCarAnnotationCoordinate(CLLocationCoordinate2D(latitude: Double(naviLocation.coordinate.latitude), longitude: Double(naviLocation.coordinate.longitude)))
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, updateTrafficFacilities trafficFacilities: [AMapNaviTrafficFacilityInfo]?) {
        guard let trafficFacilities = trafficFacilities else {
            return
        }
        NSLog("updateTrafficFacilities:")
        for aItem in trafficFacilities {
            NSLog("%@", aItem)
        }
    }
    
    func driveManager(_ driveManager: AMapNaviDriveManager, update cruiseInfo: AMapNaviCruiseInfo?) {
        guard let cruiseInfo = cruiseInfo else {
            return
        }
        NSLog("updateCruiseInfo:%@", cruiseInfo)
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
        
        if soundStringType == .passedReminder {
            //用系统自带的声音做简单例子，播放其他提示音需要另外配置
            AudioServicesPlaySystemSound(1009)
        }
        else {
            SpeechSynthesizer.Shared.speak(soundString)
        }
    }
    
    func driveManagerDidEndEmulatorNavi(_ driveManager: AMapNaviDriveManager) {
        NSLog("didEndEmulatorNavi");
    }
    
    func driveManager(onArrivedDestination driveManager: AMapNaviDriveManager) {
        NSLog("onArrivedDestination");
    }
    
    //MARK: - MAMapView Delegate
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        
        if annotation is MAPointAnnotation {
            let annotationIdentifier = "DetectedModeAnnotationIndetifier"
            
            var pointAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MAPinAnnotationView
            
            if pointAnnotationView == nil {
                pointAnnotationView = MAPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            }
            
            pointAnnotationView?.canShowCallout = false
            pointAnnotationView?.isDraggable = false
            pointAnnotationView?.image = UIImage(named: "car")
            
            return pointAnnotationView
        }
        return nil
    }

}

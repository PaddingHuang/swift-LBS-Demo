//
//  QuickStartViewController.swift
//  officialDemoNavi
//
//  Created by liubo on 10/14/16.
//  Copyright © 2016 AutoNavi. All rights reserved.
//

import UIKit

class QuickStartViewController: UIViewController, MAMapViewDelegate, AMapSearchDelegate, AMapNaviDriveManagerDelegate, DriveNaviViewControllerDelegate {

    var mapView: MAMapView!
    var driveManager: AMapNaviDriveManager!
    var search: AMapSearchAPI!
    
    var endPoint: AMapNaviPoint?
    var userLocation: MAUserLocation?
    var poiAnnotations = [MAPointAnnotation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
        initToolBar()
        initMapView()
        initDriveManager()
        initSearch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.isToolbarHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.showsUserLocation = true
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
    
    func initSearch() {
        search = AMapSearchAPI()
        search.delegate = self
    }
    
    func initToolBar() {
        let flexble = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let segmentedControl = UISegmentedControl(items: ["餐饮", "酒店", "电影"])
        segmentedControl.addTarget(self, action: #selector(self.searchAction(sender:)), for: .valueChanged)
        
        setToolbarItems([flexble, UIBarButtonItem(customView: segmentedControl), flexble], animated: false)
    }
    
    //MARK: - Search
    
    func searchAction(sender: UISegmentedControl) {
        let request = AMapPOIAroundSearchRequest()
        
        if let userLocation = userLocation {
            request.location = AMapGeoPoint.location(withLatitude: CGFloat(userLocation.location.coordinate.latitude),
                                                     longitude: CGFloat(userLocation.location.coordinate.longitude))
        }
        else {
            request.location = AMapGeoPoint.location(withLatitude: 39.990459, longitude: 116.471476)
        }
        
        request.keywords = sender.titleForSegment(at: sender.selectedSegmentIndex)
        request.sortrule = 1
        request.requireExtension = false
        
        search.aMapPOIAroundSearch(request)
    }

    //MARK: - Actions
    
    func routePlanAction() {
        guard let endPoint = endPoint else {
            return
        }
        
        driveManager.calculateDriveRoute(withEnd: [endPoint], wayPoints: nil, drivingStrategy: .singleDefault)
    }
    
    //MARK: - DriveNaviView Delegate
    
    func driveNaviViewCloseButtonClicked() {
        //停止导航
        driveManager.stopNavi()
        
        //停止语音
        SpeechSynthesizer.Shared.stopSpeak()
        
        _ = navigationController?.popViewController(animated: false)
    }
    
    //MARK: - AMapNaviDriveManager Delegate
    
    func driveManager(_ driveManager: AMapNaviDriveManager, error: Error) {
        let error = error as NSError
        NSLog("error:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func driveManager(onCalculateRouteSuccess driveManager: AMapNaviDriveManager) {
        NSLog("CalculateRouteSuccess")
        
        let driveVC = DriveNaviViewViewController()
        driveVC.delegate = self
        
        //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
        driveManager.addDataRepresentative(driveVC.driveView)
        
        _ = navigationController?.pushViewController(driveVC, animated: false)
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
    
    //MARK: - Search Delegate
    
    func aMapSearchRequest(_ request: Any!, didFailWithError error: Error!) {
        let error = error as NSError
        NSLog("error:{%d - %@}", error.code, error.localizedDescription)
    }
    
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        guard let allPois = response.pois else {
            return
        }
        
        mapView.removeAnnotations(poiAnnotations)
        poiAnnotations.removeAll()
        
        for aPoi in allPois {
            let annotation = MAPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: Double(aPoi.location.latitude), longitude: Double(aPoi.location.longitude))
            annotation.title = aPoi.name
            annotation.subtitle = aPoi.address
            
            poiAnnotations.append(annotation)
        }
        
        showPOIAnnotations()
    }
    
    func showPOIAnnotations() {
        mapView.addAnnotations(poiAnnotations)
        
        if poiAnnotations.count == 1 {
            mapView.centerCoordinate = (poiAnnotations.first?.coordinate)!
        }
        else {
            mapView.showAnnotations(poiAnnotations, animated: false)
        }
    }
    
    //MARK: - MapView Delegate
    
    func mapView(_ mapView: MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation: Bool) {
        if updatingLocation {
            self.userLocation = userLocation
        }
    }
    
    func mapView(_ mapView: MAMapView!, annotationView view: MAAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if view.annotation is MAPointAnnotation {
            
            let annotation = view.annotation as! MAPointAnnotation
            
            endPoint = AMapNaviPoint.location(withLatitude: CGFloat(annotation.coordinate.latitude), longitude: CGFloat(annotation.coordinate.longitude))
            
            routePlanAction()
        }
    }
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if annotation is MAPointAnnotation {
            let pointReuseIndetifier = "QuickStartAnnotationView"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier) as? QuickStartAnnotationView
            
            if annotationView == nil {
                annotationView = QuickStartAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
            }
            
            annotationView?.canShowCallout  = true
            annotationView?.animatesDrop    = false
            annotationView?.isDraggable     = false
            
            return annotationView
        }
        
        return nil
    }

}

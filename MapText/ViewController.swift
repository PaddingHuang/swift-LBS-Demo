//
//  ViewController.swift
//  MapText
//
//  Created by HUA on 2017/3/13.
//  Copyright © 2017年 HUA. All rights reserved.
//d7ddfc4ec7e87217f69a1f5e96f6eac2
import Alamofire
import SwiftyJSON
import UIKit
import MapKit
import SnapKit

let kCalloutViewMargin: CGFloat = -8
typealias boolHandler = (Bool) -> Void
typealias ErrorHandler = (NSError) -> Void
class ViewController: UIViewController, MAMapViewDelegate ,AMapLocationManagerDelegate,AMapSearchDelegate,AMapNaviDriveManagerDelegate , DriveNaviViewControllerDelegate {
    var locationManager : AMapLocationManager!
    var driveManager: AMapNaviDriveManager!
    var mapView: MAMapView!
    var gpsButton: UIButton!
    var search : AMapSearchAPI!
    var location :CLLocation!
    var selecttag = 0
    var annos = Array<KindsPointAnnotation>()
    var customUserLocationView: MAAnnotationView!
    var endPoint: AMapNaviPoint?
    var city:String!
    var gpsArr:[AMapPOI]?
    var gpsModelArr:[GPSModel]?
    var kindsTypes : KindsTypes?
     var coordinateQuadTree = CoordinateQuadTree()
    var shouldRegionChangeReCalculate = false
    var gpsannos = Array<ClusterAnnotation>()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        AMapServices.shared().apiKey = "d7ddfc4ec7e87217f69a1f5e96f6eac2"

        if CLLocationManager.authorizationStatus() == .denied{
                    let settingUrl = NSURL(string: UIApplicationOpenSettingsURLString)!
                    if UIApplication.shared.canOpenURL(settingUrl as URL)
                    {
                        UIApplication.shared.openURL(settingUrl as URL)
                    }
        }
        // Do any additional setup after loading the view.
        initMapView()
        initHandleView()
        
        let zoomPannelView = self.makeZoomPannelView()
        zoomPannelView.center = CGPoint.init(x: self.view.bounds.size.width -  zoomPannelView.bounds.width/2 - 10, y: self.view.bounds.size.height -  zoomPannelView.bounds.width/2 - 30-60)
        
        zoomPannelView.autoresizingMask = [UIViewAutoresizing.flexibleTopMargin , UIViewAutoresizing.flexibleLeftMargin]
        self.view.addSubview(zoomPannelView)
        
        gpsButton = self.makeGPSButtonView()
        gpsButton.center = CGPoint.init(x: gpsButton.bounds.width / 2 + 10, y:self.view.bounds.size.height -  gpsButton.bounds.width / 2 - 20 - 60)
        self.view.addSubview(gpsButton)
        gpsButton.autoresizingMask = [UIViewAutoresizing.flexibleTopMargin , UIViewAutoresizing.flexibleRightMargin]
        getData()
    }
  

  
    func getData() {
      
        let url = "http://192.168.3.199:9999/v2/mapsgps/all"
      
       gpsArr = Array.init()
        gpsModelArr = Array.init()

        //       print(serial,access_token,id122,pwd122,content,secret)
        Alamofire.request(url, method: .post, parameters: nil)
            
            
            .responseJSON(completionHandler: { (resp) in
                
                guard resp.result.error == nil else {
                
                    return
                }
                if let value = resp.result.value{
                    let json = JSON(value)
                    let code = json["code"].int
                    if code == 0{
                       let result = json["result"].array
                        for mod in result!{
                            let model = GPSModel()
                            model.Id = mod["Id"].int
                            model.LatLon = mod["LatLon"].string
                            model.Levels = mod["Levels"].string
                            model.Nums = mod["Nums"].int
                            model.RoadName = mod["RoadName"].string
                           
                            let poi = AMapPOI.init()
                            let arr = model.LatLon!.components(separatedBy: ",")
                           let lat = self.StringToFloat(str: arr[0])
                            let lon = self.StringToFloat(str: arr[1])
                       
                           let point = AMapGeoPoint.init()
                            point.latitude = lat
                            point.longitude = lon
                            poi.location = point
                            poi.name =  model.RoadName!
                            
                         self.gpsModelArr?.append(model)
                             self.gpsArr?.append(poi)
                        }
                        
                        self.synchronized(lock: self) { [weak self] in
                            
                            self?.shouldRegionChangeReCalculate = false
                            
                         
                            self?.mapView.removeAnnotations(self?.mapView.annotations)
                            
                            DispatchQueue.global(qos: .default).async(execute: { [weak self] in
                                
                                self?.coordinateQuadTree.build(withPOIs: self?.gpsArr)
                                self?.shouldRegionChangeReCalculate = true
                                self?.addAnnotations(toMapView: (self?.mapView)!)
                            })
                        }


                    }
                }
                
            })
       
    }
    func StringToFloat(str:String)->(CGFloat){
        
        let string = str
        var cgFloat: CGFloat = 0
        
        
        if let doubleValue = Double(string)
        {
            cgFloat = CGFloat(doubleValue)
        }
        return cgFloat
    }
    func addAnnotations(toMapView mapView: MAMapView) {
        synchronized(lock: self) { [weak self] in
            
            guard (self?.coordinateQuadTree.root != nil)  else {
                NSLog("tree is not ready.")
                return
            }
            
            guard let aMapView = self?.mapView else {
                return
            }
            
            let visibleRect = aMapView.visibleMapRect
            let zoomScale = Double(aMapView.bounds.size.width) / visibleRect.size.width
            let zoomLevel = Double(aMapView.zoomLevel)
            
            DispatchQueue.global(qos: .default).async(execute: { [weak self] in
                
                let annotations = self?.coordinateQuadTree.clusteredAnnotations(within: visibleRect, withZoomScale: zoomScale, andZoomLevel: zoomLevel)
               
                self?.updateMapViewAnnotations(annotations: annotations as! Array<ClusterAnnotation>)
            })
        }
    }
    
    
    //MARK: - Update Annotation
    
    func updateMapViewAnnotations(annotations: Array<ClusterAnnotation>) {
         self.gpsannos.removeAll()
        /* 用户滑动时，保留仍然可用的标注，去除屏幕外标注，添加新增区域的标注 */
        for ann in mapView.annotations {
            if ann is ClusterAnnotation {
              self.gpsannos.append(ann as! ClusterAnnotation)
            }
        }
        
        let before = NSMutableSet(array: self.gpsannos)
        before.remove(mapView.userLocation)
        
        let after: Set<NSObject> = NSSet(array: annotations) as Set<NSObject>
        
        /* 保留仍然位于屏幕内的annotation. */
        var toKeep: Set<NSObject> = NSMutableSet(set: before) as Set<NSObject>
        toKeep = toKeep.intersection(after)
        
        /* 需要添加的annotation. */
        let toAdd = NSMutableSet(set: after)
        toAdd.minus(toKeep)
        
        /* 删除位于屏幕外的annotation. */
        let toRemove = NSMutableSet(set: before)
        toRemove.minus(after)
        
        DispatchQueue.main.async(execute: { [weak self] () -> Void in
        
            self?.mapView.addAnnotations(toAdd.allObjects)
            self?.mapView.removeAnnotations(toRemove.allObjects)
           
        })
    }

    
    func synchronized(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    func initHandleView(){
        let whiteView = UIView()
        self.view.addSubview(whiteView)
        whiteView.backgroundColor = UIColor.white
        whiteView.layer.borderWidth = 1
        whiteView.layer.borderColor = UIColor.init(colorLiteralRed: 213/255.0, green: 212/255.0, blue: 210/255.0, alpha: 1).cgColor
        whiteView.layer.cornerRadius = 2
        whiteView.snp.makeConstraints { (make) in
            make.left.equalTo(self.view.snp.left).offset(10)
            make.right.equalTo(self.view.snp.right).offset(-10)
            make.bottom.equalTo(self.view.snp.bottom).offset(-5)
            make.height.equalTo(40)
        }
        //银行
        let bankBtn = UIButton()
        whiteView.addSubview(bankBtn)
        bankBtn.snp.makeConstraints { (make) in
            make.left.top.bottom.equalTo(whiteView)
            make.width.equalTo((self.view.frame.width-20)/4)
   
        }
        bankBtn.setImage(UIImage.init(named: "bar_bank"), for: .normal)
        bankBtn.setTitle(" 银行", for: .normal)
        bankBtn.setTitleColor(UIColor.black, for: .normal)
        bankBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: 0.9)
        bankBtn.addTarget(self, action: #selector(bankBtnClick), for: .touchUpInside)
        //停车场
        let stopBtn = UIButton()
        whiteView.addSubview(stopBtn)
        stopBtn.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(whiteView)
            make.width.equalTo((self.view.frame.width-20)/4)
            make.left.equalTo(bankBtn.snp.right)
        }
        stopBtn.setImage(UIImage.init(named: "park"), for: .normal)
        stopBtn.setTitle(" 停车场", for: .normal)
        stopBtn.setTitleColor(UIColor.black, for: .normal)
        stopBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight:0.9)
        stopBtn.addTarget(self, action: #selector(stopBtnClick), for: .touchUpInside)
       

        //加油
        let oilBtn = UIButton()
        whiteView.addSubview(oilBtn)
        oilBtn.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(whiteView)
            make.width.equalTo((self.view.frame.width-20)/4)
            make.left.equalTo(stopBtn.snp.right)

        }
        oilBtn.setImage(UIImage.init(named: "oil"), for: .normal)
        oilBtn.setTitle(" 加油站", for: .normal)
        oilBtn.setTitleColor(UIColor.black, for: .normal)
        oilBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: 0.9)
        oilBtn.addTarget(self, action: #selector(oilBtnClick), for: .touchUpInside)
        //导航
        let derictBtn = UIButton()
        whiteView.addSubview(derictBtn)
        derictBtn.snp.makeConstraints { (make) in
            make.top.bottom.equalTo(whiteView)
            make.width.equalTo((self.view.frame.width-20)/4)
            make.left.equalTo(oilBtn.snp.right)
            
        }
        derictBtn.setImage(UIImage.init(named: "navigation"), for: .normal)
        derictBtn.setTitle(" 导航", for: .normal)
        derictBtn.setTitleColor(UIColor.black, for: .normal)
        derictBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: 0.9)
         derictBtn.addTarget(self, action: #selector(derictBtnClick), for: .touchUpInside)
        
        let line1 = UIImageView()
          whiteView.addSubview(line1)
         line1.backgroundColor = UIColor.init(colorLiteralRed: 213/255.0, green: 212/255.0, blue: 210/255.0, alpha: 1)
        line1.snp.makeConstraints { (make) in
            make.top.equalTo(whiteView.snp.top).offset(5)
            make.bottom.equalTo(whiteView.snp.bottom).offset(-5)
            make.width.equalTo(1)
            make.left.equalTo(bankBtn.snp.right)
            
        }
        
        let line2 = UIImageView()
        whiteView.addSubview(line2)
        line2.backgroundColor = UIColor.init(colorLiteralRed: 213/255.0, green: 212/255.0, blue: 210/255.0, alpha: 1)
        line2.snp.makeConstraints { (make) in
            make.top.equalTo(whiteView.snp.top).offset(5)
             make.bottom.equalTo(whiteView.snp.bottom).offset(-5)
            make.width.equalTo(1)
            make.left.equalTo(stopBtn.snp.right)
            
        }
        let line3 = UIImageView()
        whiteView.addSubview(line3)
        line3.backgroundColor = UIColor.init(colorLiteralRed: 213/255.0, green: 212/255.0, blue: 210/255.0, alpha: 1)
        line3.snp.makeConstraints { (make) in
            make.top.equalTo(whiteView.snp.top).offset(5)
            make.bottom.equalTo(whiteView.snp.bottom).offset(-5)
            make.width.equalTo(1)
            make.left.equalTo(oilBtn.snp.right)
            
        }

       
      
    }
    
    func makeGPSButtonView() -> UIButton! {
        let ret = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: 40))
        ret.backgroundColor = UIColor.white
        ret.layer.cornerRadius = 4
        
        ret.setImage(UIImage.init(named: "gpsStat1"), for: UIControlState.normal)
        ret.addTarget(self, action: #selector(self.gpsAction), for: UIControlEvents.touchUpInside)
        
        return ret
    }
    
    func makeZoomPannelView() -> UIView {
        let ret = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 53, height: 98))
        
        let incBtn = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: 53, height: 49))
        incBtn.setImage(UIImage.init(named: "increase"), for: UIControlState.normal)
        incBtn.sizeToFit()
        incBtn.addTarget(self, action: #selector(self.zoomPlusAction), for: UIControlEvents.touchUpInside)
        
        let decBtn = UIButton.init(frame: CGRect.init(x: 0, y: 49, width: 53, height: 49))
        decBtn.setImage(UIImage.init(named: "decrease"), for: UIControlState.normal)
        decBtn.sizeToFit()
        decBtn.addTarget(self, action: #selector(self.zoomMinusAction), for: UIControlEvents.touchUpInside)
        
        ret.addSubview(incBtn)
        ret.addSubview(decBtn)
        
        return ret
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    func initMapView() {
        mapView = MAMapView(frame: self.view.bounds)
        mapView.delegate = self
        mapView.autoresizingMask = [UIViewAutoresizing.flexibleHeight, UIViewAutoresizing.flexibleWidth]
        mapView.showsUserLocation = true
        self.view.addSubview(mapView)
        self.mapView.setZoomLevel(17, animated: true)
        self.locationManager = AMapLocationManager.init()
        self.locationManager.delegate = self
        self.locationManager.locatingWithReGeocode = true
        self.locationManager.startUpdatingLocation()
        self.locationManager.distanceFilter = 200
        AMapServices.shared().enableHTTPS = true
        self.locationManager.locationTimeout = 6
        self.locationManager.reGeocodeTimeout = 3

        
        mapView.userTrackingMode = .followWithHeading
        search = AMapSearchAPI()
        search.delegate = self
       


       
              }
    
    //MARK:- event handling
    func zoomPlusAction() {
        let oldZoom = self.mapView.zoomLevel
        self.mapView.setZoomLevel(oldZoom+1, animated: true)
    }
    
    func zoomMinusAction() {
        let oldZoom = self.mapView.zoomLevel
        self.mapView.setZoomLevel(oldZoom-1, animated: true)
    }
    
    func gpsAction() {
        if(self.mapView.userLocation.isUpdating && self.mapView.userLocation.location != nil) {
            self.mapView.setCenter(self.mapView.userLocation.location.coordinate, animated: true)
            self.gpsButton.isSelected = true
        }
    }
    
    func amapLocationManager(_ manager: AMapLocationManager!, didUpdate location: CLLocation!) {
         self.mapView.setCenter(location.coordinate, animated: true)
        self.location = location
        let request = AMapReGeocodeSearchRequest()
        request.location = AMapGeoPoint.location(withLatitude: CGFloat(location.coordinate.latitude), longitude: CGFloat(location.coordinate.longitude))
        request.requireExtension = true
        search.aMapReGoecodeSearch(request)
              
    }
    func onReGeocodeSearchDone(_ request: AMapReGeocodeSearchRequest!, response: AMapReGeocodeSearchResponse!) {
        
        if response.regeocode == nil {
            return
        }
      
        self.city = response.regeocode.addressComponent.city

        //解析response获取地址描述，具体解析见 Demo
    }

    //银行按钮点击事件
    func bankBtnClick(){
        if (self.location != nil) {
             self.kindsTypes = .bank
            let request = AMapPOIAroundSearchRequest()
            
            request.location = AMapGeoPoint.location(withLatitude: CGFloat(location.coordinate.latitude), longitude:CGFloat(location.coordinate.longitude))
            request.keywords = "银行"
            
            request.requireExtension = true
            search.aMapPOIAroundSearch(request)
         
        }
    }
    
    //停车场按钮点击事件
    func stopBtnClick(){
        if (self.location != nil) {
             self.kindsTypes = .stop
        let request = AMapPOIAroundSearchRequest()
        request.location = AMapGeoPoint.location(withLatitude: CGFloat(location.coordinate.latitude), longitude:CGFloat(location.coordinate.longitude))
        request.keywords = "停车场"
        request.requireExtension = true
        search.aMapPOIAroundSearch(request)
                    }
    }
    
    //油站按钮点击事件
    func oilBtnClick(){
    
        if (self.location != nil) {
           self.kindsTypes = .oil
            let request = AMapPOIAroundSearchRequest()
                    request.location = AMapGeoPoint.location(withLatitude: CGFloat(location.coordinate.latitude), longitude:CGFloat(location.coordinate.longitude))
            request.keywords = "加油站"
            request.requireExtension = true
            search.aMapPOIAroundSearch(request)
           
        }
    }
    
    //导航按钮点击事件
    func derictBtnClick(){
        if driveManager != nil {
            driveManager.stopNavi()
        }
        let search  = SearchViewController()
        search.city = self.city
        self.navigationController?.pushViewController(search, animated: true)
      
    }
    
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        
        if response.count == 0 {
            return
        }
       
      
                  for aPOI in response.pois {
            let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(aPOI.location.latitude), longitude: CLLocationDegrees(aPOI.location.longitude))
            let anno = KindsPointAnnotation()
            anno.coordinate = coordinate
            anno.title = aPOI.name
            anno.subtitle = aPOI.address
            anno.kindsTypes = self.kindsTypes
            annos.append(anno)
           
        }
       mapView.addAnnotations(annos)
      // mapView.showAnnotations(annos, animated: true)
     
      
    }
    func mapView(_ mapView: MAMapView!, regionDidChangeAnimated animated: Bool) {
  

        addAnnotations(toMapView: self.mapView)
     
    }

    
    
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        if annotation.isKind(of: KindsPointAnnotation.self) {
            let pointReuseIndetifier = "pointReuseIndetifiers"
            var annotationView: MAPinAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier) as! MAPinAnnotationView?
            
            if annotationView == nil {
                annotationView = QuickStartAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
            }
       let ann =     annotation as! KindsPointAnnotation
            if   ann.kindsTypes == .stop {
                annotationView?.image = UIImage.init(named: "park")
            }else  if   ann.kindsTypes == .oil {
                annotationView?.image = UIImage.init(named: "oil")
            }else  if   ann.kindsTypes == .bank {
                annotationView?.image = UIImage.init(named: "bar_bank")
            }
            
            annotationView!.canShowCallout = true
            annotationView!.animatesDrop = false
            annotationView!.isDraggable = true
            return annotationView!
        }else  if annotation is ClusterAnnotation {
            let pointReuseIndetifier = "pointReuseIndetifier"
            
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier) as? ClusterAnnotationView
            
            if annotationView == nil {
                annotationView = ClusterAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
            }
            
            annotationView?.annotation = annotation
            annotationView?.count = UInt((annotation as! ClusterAnnotation).count)
            
            return annotationView
        }
        return nil
    }
    func mapView(_ mapView: MAMapView!, didSelect view: MAAnnotationView!) {
      
       
    }
    func mapView(_ mapView: MAMapView!, didAddAnnotationViews views: [Any]!) {
        let annoationview = views.first as! MAAnnotationView
        
        if(annoationview.annotation .isKind(of: MAUserLocation.self)) {
            let rprt = MAUserLocationRepresentation.init()
          
            rprt.image = UIImage.init(named: "userPosition")
            
            
            mapView.update(rprt)
            
            annoationview.calloutOffset = CGPoint.init(x: 0, y: 0)
            annoationview.canShowCallout = false
            self.customUserLocationView = annoationview
        }
    }
    func mapView(_ mapView:MAMapView!, didUpdate userLocation: MAUserLocation!, updatingLocation:Bool ) {
        if(!updatingLocation && self.customUserLocationView != nil) {
            UIView.animate(withDuration: 0.1, animations: {
                let degree = userLocation.heading.trueHeading
                let radian = (degree * M_PI) / 180.0
                self.customUserLocationView.transform = CGAffineTransform.init(rotationAngle: CGFloat(radian))
            })
        }
    }
    func mapView(_ mapView: MAMapView!, annotationView view: MAAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if view.annotation is KindsPointAnnotation {
            let annotation = view.annotation as! KindsPointAnnotation
            endPoint = AMapNaviPoint.location(withLatitude: CGFloat(annotation.coordinate.latitude), longitude: CGFloat(annotation.coordinate.longitude))
            
            routePlanAction()
        }
    }
    func routePlanAction() {
        guard let endPoint = endPoint else {
            return
        }
        if (driveManager == nil) {
            driveManager = AMapNaviDriveManager()
            driveManager.delegate = self
            driveManager.allowsBackgroundLocationUpdates = true
            driveManager.pausesLocationUpdatesAutomatically = false
        }
        
        driveManager.calculateDriveRoute(withEnd: [endPoint], wayPoints: nil, drivingStrategy: .singleDefault)
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

    //MARK: - DriveNaviView Delegate
    
    func driveNaviViewCloseButtonClicked() {
        //停止导航
        driveManager.stopNavi()
        
        //停止语音
        SpeechSynthesizer.Shared.stopSpeak()
        
        _ = navigationController?.popViewController(animated: false)
    }

}


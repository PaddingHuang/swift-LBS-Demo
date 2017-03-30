//
//  SearchViewController.swift
//  MapText
//
//  Created by HUA on 2017/3/16.
//  Copyright © 2017年 HUA. All rights reserved.
//
import SwiftyJSON
import UIKit
import SnapKit
class SearchViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,IFlyRecognizerViewDelegate,AMapSearchDelegate,UITextFieldDelegate{
    var iflyRecognizerView : IFlyRecognizerView!
    var tabView:UITableView?
    var TF = UITextField()
    var curResult = ""
    var search : AMapSearchAPI!
    var city:String!
    var dataArr:[SearchModel]?
    var location:CLLocation?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataArr = Array.init()
        initTableView()
        initSearch()
        
    }
    func initSearch(){
        search = AMapSearchAPI()
        search.delegate = self
    }
    func initTableView(){
        self.tabView = UITableView()
        self.tabView?.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 244/255.0, blue: 240/255.0, alpha: 1)
        self.tabView?.delegate = self
        self.tabView?.dataSource = self
        self.tabView?.frame = self.view.frame
        self.view.addSubview(self.tabView!)
        self.tabView?.separatorStyle = UITableViewCellSeparatorStyle(rawValue: 0)!
        self.tabView?.tableHeaderView = initHeader()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mulit = MultiRoutePlanViewController()
        mulit.model = self.dataArr?[indexPath.row]
      
      self.navigationController?.pushViewController(mulit, animated: true)
//       self.navigationController?.pushViewController(mulit, animated: true)
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArr!.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "diy_cell") as? SearchTableViewCell
        
        if(cell == nil){//因为是纯代码实现，没有对行里的cell做注册，这里是 做注册， 注册一次后，下次会继续使用这个缓存
            cell = SearchTableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: "diy_cell");
            //以上使用了系统默认的一个cell样式
        }
        let model = self.dataArr?[indexPath.row]
        cell?.setModel(model: model!)
        cell?.selectionStyle = .none
        cell?.accessoryType = .disclosureIndicator
        
        return cell!
    }
    func initHeader()->UIView{
    let header = UIView()
    header.frame = CGRect.init(x: 0, y: 0, width: self.view.frame.width, height: 65)
    let whiteView = UIView()
    header.addSubview(whiteView)
    whiteView.backgroundColor = UIColor.white
    whiteView.frame = CGRect.init(x: 10, y:10, width: self.view.frame.width-20, height: 45)
    whiteView.layer.cornerRadius = 5
    
    //返回按钮
    let backBtn = UIButton()
    backBtn.setImage(UIImage.init(named: "map_icon_out"), for: .normal)
    backBtn.frame = CGRect.init(x: 0, y:0, width: 45, height: 45)
    whiteView.addSubview(backBtn)
    backBtn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
    //输入框
    
    whiteView.addSubview(TF)
    TF.frame = CGRect.init(x: 50, y:0, width:self.view.frame.width-110 , height: 45)
    TF.placeholder = "请输入目的地"
    TF.becomeFirstResponder()
    TF.delegate = self
    TF.addTarget(self, action: #selector(textChange(_:)), for: .editingChanged)
    //语音
    let voiceBtn = UIButton()
    voiceBtn.frame = CGRect.init(x: self.view.frame.width-65, y:0, width: 45, height: 45)
    voiceBtn.setImage(UIImage.init(named: "map_icon_voice"), for: .normal)
    voiceBtn.setImage(UIImage.init(named: "voice"), for: .highlighted)
    whiteView.addSubview(voiceBtn)
    voiceBtn.addTarget(self, action: #selector(voiceBtnClick), for: .touchUpInside)
    let line1 = UIImageView()
    line1.frame = CGRect.init(x: 45, y:5, width: 1, height: 35)
    line1.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 244/255.0, blue: 240/255.0, alpha: 1)
    whiteView.addSubview(line1)
    
    let line2 = UIImageView()
    line2.frame = CGRect.init(x: self.view.frame.width-65, y:5, width: 1, height: 35)
    line2.backgroundColor = UIColor.init(colorLiteralRed: 246/255.0, green: 244/255.0, blue: 240/255.0, alpha: 1)
    whiteView.addSubview(line2)
        return header
    }
    func backBtnClick(){
       _ = self.navigationController?.popViewController(animated: true)
    }
    func voiceBtnClick(){
        self.TF.text = ""
        self.TF.resignFirstResponder()
        self.iflyRecognizerView = IFlyRecognizerView.init(center: self.view.center)
        self.iflyRecognizerView.delegate = self
        self.iflyRecognizerView.setParameter("lat", forKey: IFlySpeechConstant.ifly_DOMAIN())
//        self.iflyRecognizerView.setParameter("asrview.pcm", forKey: IFlySpeechConstant.asr_AUDIO_PATH())
        self.iflyRecognizerView.start()
    }
    func onError(_ error: IFlySpeechError!) {
        
    }
    
    func onResult(_ resultArray: [Any]!, isLast: Bool) {
        if isLast == false{
        var result = ""
        let dic  = JSON(resultArray)
        let dic2 = dic[0].dictionary
        for key in dic2!.keys{
            result.append(key)
        }
        let resultFromJson = ISRDataHelper.string(fromJson: result)
       
        self.TF.text = "\(self.TF.text!)\(resultFromJson!)"
            
        }
        else{
            searchForText(text: self.TF.text!)
        }
        
    }
    //搜索字段
    func searchForText(text:String){
        let request = AMapPOIKeywordsSearchRequest.init()
        request.keywords = text
        request.requireExtension = true
        request.city = self.city
        request.cityLimit = true
        request.requireSubPOIs = true
        search.aMapPOIKeywordsSearch(request)
    }
    func onPOISearchDone(_ request: AMapPOISearchBaseRequest!, response: AMapPOISearchResponse!) {
        
        if response.count == 0 {
             self.dataArr?.removeAll()
             self.tabView?.reloadData()
            return
        }
        guard let allPois = response.pois else {
            return
        }
         self.dataArr?.removeAll()
    
              for aPoi in allPois {
         print("\(aPoi.name!)(\(aPoi.address!))")
                let model = SearchModel()
                model.name = aPoi.name
                model.address = aPoi.address
                model.location = aPoi.location
                self.dataArr?.append(model)
               
        }
            self.tabView?.reloadData()
        }
  
   
    func textChange(_ textField: UITextField){
        if textField.text != "" {
            searchForText(text: textField.text!)
        }else{
            self.dataArr?.removeAll()
            self.tabView?.reloadData()

        }

    }
    
}

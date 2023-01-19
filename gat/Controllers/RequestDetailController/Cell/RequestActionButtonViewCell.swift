//
//  RequestActionButtonViewCell.swift
//  gat
//
//  Created by HungTran on 4/28/17.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/**Định nghĩa kiểu của Action.
 Button: Dạng nút bấm
 Text: Dạng hiển thị thông báo*/
enum RequestActionInputType: Int {
    case Button
    case Text
}

enum ActionStateStyle: Int {
    case Primary
    case Success
    case Error
}

enum ActionStateType: Int {
    case Active
    case Normal
}

class RequestActionData {
    /**Lưu mã của action, để kiểm tra để thực hiện action*/
    var actionId: Int = -1
    /**Nhãn của nút bấm*/
    var buttonLabel: String = ""
    /**Hiển border hay không (border viền mảnh)*/
    var hideBorder: Bool = true
    /**Kiểu của cell: Button - Nút bấm, Text - Khu vực điền text*/
    var inputType: RequestActionInputType = .Button
    /**Màu của Action*/
    var style: ActionStateStyle = .Primary
    /**Trạng thái của Action*/
    var state: ActionStateType = .Normal
    
    var currentStatus: Int = -1
    var newStatus: Int = -1
    
    /**Lấy màu của nút bấm dựa vào style và trạng thái*/
    var buttonActionColor: UIColor {
        get {
            switch style {
            case .Primary:
                switch state {
                case .Active: return Gat.Color.requestActionButtonPrimaryActive
                case .Normal: return Gat.Color.requestActionButtonPrimaryNormal
                }
            case .Success:
                switch state {
                case .Active: return Gat.Color.requestActionButtonSuccessActive
                case .Normal: return Gat.Color.requestActionButtonSuccessNormal
                }
            case .Error:
                switch state {
                case .Active: return Gat.Color.requestActionButtonErrorActive
                case .Normal: return Gat.Color.requestActionButtonErrorNormal
                }
            }
        }
    }
    
    /**Lấy ảnh của checkIcon dựa vào style và trạng thái*/
    var checkIconImage: UIImage? {
        get {
            switch style {
            case .Primary:
                switch state {
                case .Active: return Gat.Image.iconWhiteCheck
                case .Normal: return nil
                }
            case .Success:
                switch state {
                case .Active: return nil
                case .Normal: return nil
                }
            case .Error:
                switch state {
                case .Active: return Gat.Image.iconWhiteCancel
                case .Normal: return nil
                }
            }
        }
    }
    
    /**Lấy màu của checkIcon dựa vào style và trạng thái*/
    var checkIconColor: UIColor {
        get {
            switch style {
            case .Primary:
                switch state {
                case .Active: return Gat.Color.requestActionButtonPrimaryActive
                case .Normal: return Gat.Color.requestActionCheckButtonNormal
                }
            case .Success:
                switch state {
                case .Active: return Gat.Color.requestActionButtonSuccessActive
                case .Normal: return Gat.Color.requestActionButtonSuccessNormal
                }
            case .Error:
                switch state {
                case .Active: return Gat.Color.requestActionButtonErrorActive
                case .Normal: return Gat.Color.requestActionCheckButtonNormal
                }
            }
        }
    }
    
    /**Kích hoạt sự kiện cho action hay không (cho phép bấm hay không)?
     true: có thể click, false: không thể click*/
    var isEnabled: Bool = true
    /**Đánh dấu là ẩn cả Action hay không*/
    var isHiddenAll: Bool = false
    /**Đánh dấu là có ẩn check hay không*/
    var isHiddenCheckStatus: Bool = false
    /**Giá trị của loại input text (nếu có)*/
    var text: String = ""
    var isFirst: Bool = false
    var isLast: Bool = false
    
    init(actionId: Int = -1,
         buttonLabel: String = "",
         hideBorder: Bool = true,
         inputType: RequestActionInputType = .Button,
         style: ActionStateStyle = .Primary,
         state: ActionStateType = .Normal,
         isEnabled: Bool = true,
         isHiddenAll: Bool = false,
         isHiddenCheckStatus: Bool = false,
         text: String = "",
         isFirst: Bool = false,
         isLast: Bool = false,
         currentStatus: Int = -1,
         newStatus: Int = -1
        ) {
        self.actionId = actionId
        self.buttonLabel = buttonLabel
        self.hideBorder = hideBorder
        self.inputType = inputType
        self.style = style
        self.state = state
        self.isEnabled = isEnabled
        self.isHiddenAll = isHiddenAll
        self.isHiddenCheckStatus = isHiddenCheckStatus
        self.text = text
        self.isFirst = isFirst
        self.isLast = isLast
        self.currentStatus = currentStatus
        self.newStatus = newStatus
    }
}

class RequestActionButtonViewCell: UITableViewCell {
    
    @IBOutlet weak var checkAreaView: UIView!
    @IBOutlet weak var checkAreaWidth: NSLayoutConstraint!
    @IBOutlet weak var checkIcon: UIView!
    @IBOutlet weak var checkIconImage: UIImageView!
    @IBOutlet weak var topLine: UIView!
    @IBOutlet weak var bottomLine: UIView!
    @IBOutlet weak var checkTopLine: UIView!
    @IBOutlet weak var checkBottomLine: UIView!
    @IBOutlet weak var backgroundBorder: UIView!
    @IBOutlet weak var foregroundButton: UIView!
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var textArea: UIView!
    @IBOutlet weak var textValue: UILabel!
    
    /**Cài đặt dữ liệu của từng Cell*/
    var requestActionData: Variable<RequestActionData?> = Variable(nil)
    
    private var disposeBag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
        self.defaultConfig()
        
        requestActionData.asObservable()
            .filter({ (data) -> Bool in
                return data != nil
            })
            .flatMap({ (data) -> Observable<RequestActionData> in
                return Observable.just(data!)
            })
            .subscribe(onNext: { [weak self] (data) in
                self?.configViewCell(data: data)
            }).addDisposableTo(self.disposeBag)
    }

    /**Config View Cell: Config thay đổi theo trạng thái của dữ liệu được gửi vào*/
    private func configViewCell(data: RequestActionData) {
        self.layoutIfNeeded()
        
        self.textArea.isHidden = (data.inputType == .Button)
        self.textValue.text = data.text
        self.actionLabel.text = data.buttonLabel
        
        self.checkIconImage.image = data.checkIconImage
        self.backgroundBorder.isHidden = (data.inputType == .Text || data.hideBorder)
        self.foregroundButton.isHidden = (data.inputType == .Text)
        self.checkIcon.backgroundColor = data.checkIconColor
        self.topLine.backgroundColor = data.checkIconColor
        self.bottomLine.backgroundColor = data.checkIconColor
        
        self.backgroundBorder.circleCorner(radius: self.backgroundBorder.frame.height/2.0, thickness: 1.0, color: data.buttonActionColor)
        self.backgroundBorder.circleCorner(radius: self.backgroundBorder.frame.height/2.0, thickness: 1.0, color: data.buttonActionColor)
        self.backgroundBorder.circleCorner(radius: self.backgroundBorder.frame.height/2.0, thickness: 1.0, color: data.buttonActionColor)
        self.foregroundButton.backgroundColor = data.buttonActionColor
        
        self.topLine.isHidden = data.isFirst
        self.bottomLine.isHidden = data.isLast
        
        /**Cài đặt trạng thái Check Status*/
        self.checkAreaWidth.constant = ( data.inputType == .Text || data.isHiddenCheckStatus) ? 1.0 : 31.0
        self.checkAreaView.isHidden = ( data.inputType == .Text || data.isHiddenCheckStatus )
        
        self.isUserInteractionEnabled = !(data.state == .Active)
    }
    
    /**defaultConfig: Cấu hình các thành phần mặc định, (kiểu như bo góc, màu mè mặc định)*/
    private func defaultConfig() {
        self.layoutIfNeeded()
        self.checkIcon.circleCorner()
        self.foregroundButton.cornerRadius(radius: self.foregroundButton.frame.height/2.0)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

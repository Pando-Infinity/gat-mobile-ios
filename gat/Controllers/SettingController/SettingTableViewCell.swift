//
//  SettingTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 18/04/2017.
//  Copyright © 2017 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SettingItem {
    var id: Int = -1
    var name: String = ""
    var info: String = ""
    var enabled: Bool = true
    var textColor: UIColor = #colorLiteral(red: 0.568627451, green: 0.568627451, blue: 0.568627451, alpha: 1)
    var infoColor: UIColor = #colorLiteral(red: 0.568627451, green: 0.568627451, blue: 0.568627451, alpha: 1)
    var image: UIImage? {
        get {
            return enabled ? normalImage : disableImage
        }
    }
    var normalImage: UIImage? = nil
    var disableImage: UIImage? = nil
    var showForwardButton: Bool = true
    var show: Bool = true
    
    init(id: Int = -1, name: String = "", info: String = "", enabled: Bool = true, textColor: UIColor = #colorLiteral(red: 0.568627451, green: 0.568627451, blue: 0.568627451, alpha: 1), infoColor: UIColor = #colorLiteral(red: 0.568627451, green: 0.568627451, blue: 0.568627451, alpha: 1), normalImage: UIImage? = nil, disableImage: UIImage? = nil, showForwardButton: Bool = true, show: Bool = true) {
        self.id = id
        self.name = name
        self.info = info
        self.enabled = enabled
        self.normalImage = normalImage
        self.disableImage = disableImage
        self.textColor = textColor
        self.show = show
        self.showForwardButton = showForwardButton
        self.infoColor = infoColor
    }
}

class SettingTableViewCell: UITableViewCell {
    //MARK: - UI Properties
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var backImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    //MARK: - Public Data Properties
    var settingData: Variable<SettingItem> = Variable(SettingItem())
    
    //MARK: - Private Data Properties
    private var disposeBag = DisposeBag()
    
    //MARK: - ViewState
    override func awakeFromNib() {
        super.awakeFromNib()
        settingData.asObservable().filter { (data) -> Bool in
            return data.id >= 0
        }.subscribe(onNext: { [weak self] data in
            self?.iconImageView.image = data.image
            self?.label.text = data.name
            self?.nameLabel.text = data.info
            self?.label.textColor = data.textColor
            self?.nameLabel.textColor = data.infoColor
            self?.backImageView.isHidden = !data.showForwardButton
        })
            .disposed(by: self.disposeBag)
    }
    
    //MARK: - Deinit
    deinit {
        print("Đã huỷ: ", className)
    }
}

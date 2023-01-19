//
//  EditImageTableViewCell.swift
//  gat
//
//  Created by Vũ Kiên on 21/04/2018.
//  Copyright © 2018 GaTBook. All rights reserved.
//

import UIKit
import RxSwift
import ImagePicker

class EditImageTableViewCell: UITableViewCell, UINavigationControllerDelegate {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var changeImageButton: UIButton!
    
    weak var controller: EditInfoUserViewController?
    var imagePicker = UIImagePickerController()
    fileprivate let disposeBag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.event()
    }
    
    // MARK: - Data
    fileprivate func compressAndResize(image: UIImage) {
        if let img = image.resizeAndCompress(0.8, maxBytes: 1000*1000) {
            self.controller?.editImage.onNext(img)
        }
    }
    
    // MARK: - UI
    func setup() {
        Repository<UserPrivate, UserPrivateObject>
            .shared
            .getFirst().map { $0.profile }
            .filter { $0 != nil }
            .bind { [weak self] (profile) in
                self?.avatarImageView.sd_setImage(with: URL(string: AppConfig.sharedConfig.setUrlImage(id: profile!.imageId))!, placeholderImage: DEFAULT_USER_ICON)
                self?.layoutIfNeeded()
                self?.avatarImageView.circleCorner()
                self?.avatarImageView.layer.borderColor = #colorLiteral(red: 0.5568627451, green: 0.7647058824, blue: 0.8745098039, alpha: 1)
                self?.avatarImageView.layer.borderWidth = 3
                self?.changeImageButton.setTitle(Gat.Text.EditUser.CHANGE_AVATAR_TITLE.localized(), for: .normal)
            }
            .disposed(by: self.disposeBag)
    }
    
    fileprivate func pickImage(){
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false
            
            self.controller?.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // MARK: - Event
    fileprivate func event() {
        self.changeImageButton.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            self?.pickImage()
        }).disposed(by: self.disposeBag)
    }
}

extension EditImageTableViewCell: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
                return
            }
        self.avatarImageView.image = image
        self.compressAndResize(image: image)
        picker.dismiss(animated: true, completion: nil)
    }
}

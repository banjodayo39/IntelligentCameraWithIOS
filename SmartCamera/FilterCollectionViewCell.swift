//
//  FilterCollectionViewCell.swift
//  SmartCamera
//
//  Created by Dayo Banjo on 3/13/21.
//

import UIKit

class FilterCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "FilterCollectionViewCell"

    var filterImage : UIImageView = {
        let image = UIImage(named: "tree")
        let imageV = UIImageView(frame: CGRect(x: 5, y: 5, width: 70, height: 70))
        imageV.layer.borderWidth = 1
        imageV.layer.borderColor = UIColor.white.cgColor
        imageV.layer.cornerRadius = imageV.frame.height / 2
        imageV.clipsToBounds = true
        imageV.image = image
        return imageV
    }()
    
    let subView : UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 80)) 
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.cornerRadius = view.frame.height / 2
        view.clipsToBounds = true
        return view 
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
        
    }
    
    func configureFilter(_ filter: String){
        filterImage.image = UIImage(named: filter)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initView(){
        subView.addSubview(filterImage)
        addSubview(subView)
    }
    
    func transformImageToLarge(){
        UIView.animate(withDuration: 0.2) { 
            self.transform = CGAffineTransform(scaleX: 1.50, y: 1.50)
            self.subView.layer.borderColor = UIColor.blue.cgColor
            self.subView.layer.borderWidth = 1.3
        }
    }
    
    func resizeTransformToStandard(){
        UIView.animate(withDuration: 0.2) { 
            self.subView.layer.borderColor = UIColor.white.cgColor
            self.transform = CGAffineTransform.identity
        }
    }
}


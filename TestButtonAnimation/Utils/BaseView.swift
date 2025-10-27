//
//  BaseView.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/24/25.
//

import UIKit

class BaseView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setHierarchy()
        setLayoutConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setHierarchy() {
        
    }
    
    func setLayoutConstraints() {
        
    }
}

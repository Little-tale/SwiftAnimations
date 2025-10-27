//
//  MorphMenuViewController.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/24/25.
//

import UIKit
import SnapKit

final class MorphMenuViewController: UIViewController {
    private let baseView = MorphMenuView()
    
    override func loadView() {
        super.loadView()
        self.view = baseView
        self.view.backgroundColor = .white
    }
    
}

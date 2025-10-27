//
//  TestZoomViewController.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/27/25.
//

import UIKit
import SnapKit

final class TestZoomViewController: UIViewController, ZoomTransitionable {
    
    let searchBar = UIButton().after {
        $0.tintColor = .blue
        $0.backgroundColor = .red
        $0.layer.cornerRadius = 8
        $0.layer.shadowColor = UIColor.black.cgColor
    }

    private var animator: ZoomTransitionAnimator?
    
    private let navDelegate = ZoomNavDelegate()
    
    var zoomSourceView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationController?.delegate = navDelegate
        self.zoomSourceView = searchBar
        view.addSubview(searchBar)
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        searchBar.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
    }

    @objc
    func didTapSearch(_ sender: UIButton) {
        let detail = TestZoomNextViewController()
        
        if let nav = navigationController {
            navDelegate.interactivePop = ZoomInteractivePop(navigationController: nav, attachTo: detail.view)
            navigationController?.pushViewController(detail, animated: true)
        }
    }

    // UINavigationControllerDelegate
    func navigationController(_ nav: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard operation == .push else { return nil }
        return animator
    }
}

final class TestZoomNextViewController: UIViewController, ZoomTransitionable {
    
    var zoomSourceView: UIView? { self.view }
    
    private let centerTitleLabel = UILabel().after {
        $0.text = "Center"
        $0.font = .systemFont(ofSize: 32, weight: .bold)
    }
    
    private let ifNeedBackButton = UIButton().after {
        $0.setTitle("뒤로가기", for: .normal)
        $0.backgroundColor = .blue
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .red
        
        view.addSubview(centerTitleLabel)
        view.addSubview(ifNeedBackButton)
        
        centerTitleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        ifNeedBackButton.snp.makeConstraints { make in
            make.top.equalTo(centerTitleLabel.snp.bottom).offset(10)
            make.centerX.equalTo(centerTitleLabel)
        }
        
        ifNeedBackButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            self.dismiss(animated: true)
        }), for: .touchUpInside)
    }
}

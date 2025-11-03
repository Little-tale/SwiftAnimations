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
    
    deinit {
        print("** Dead \(Self.description())")
    }
}

final class TestZoomNextViewController2: UIViewController, ZoomTransitionable {
    
    var zoomSourceView: UIView? { self.view }
    
    private let centerTitleLabel = UILabel().after {
        $0.text = "Center"
        $0.font = .systemFont(ofSize: 32, weight: .bold)
    }
    
    private let ifNeedBackButton = UIButton().after {
        $0.setTitle("뒤로가기", for: .normal)
        $0.backgroundColor = .blue
    }
    
    private let scrollView = UIScrollView().after {
        $0.backgroundColor = .green
    }
    
    override func loadView() {
        super.loadView()
        
        view.backgroundColor = .red
        
        view.addSubview(centerTitleLabel)
        view.addSubview(ifNeedBackButton)
        view.addSubview(scrollView)
        
        centerTitleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        ifNeedBackButton.snp.makeConstraints { make in
            make.top.equalTo(centerTitleLabel.snp.bottom).offset(10)
            make.centerX.equalTo(centerTitleLabel)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(ifNeedBackButton.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        let labels = (1...40).map { String($0) }

        var previousLabel: UILabel? = nil

        labels.enumerated().forEach { index, text in
            let label = UILabel()
            label.text = text
            scrollView.addSubview(label)
            
            label.snp.makeConstraints { make in
                make.horizontalEdges.equalToSuperview().inset(16)
                if index == 0 {
                    make.top.equalToSuperview().offset(16)
                } else {
                    make.top.equalTo(previousLabel!.snp.bottom).offset(12)
                }
            }
            
            previousLabel = label
        }
        
        previousLabel?.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(16)
        }

        ifNeedBackButton.addAction(UIAction(handler: { [weak self] _ in
            guard let self else { return }
            self.dismiss(animated: true)
        }), for: .touchUpInside)
    }
    
    deinit {
        print("** Dead \(Self.description())")
    }
}

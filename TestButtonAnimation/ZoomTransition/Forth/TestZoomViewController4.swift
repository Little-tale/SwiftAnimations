//
//  TestZoomViewController4.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/27/25.
//

import UIKit
import SnapKit

final class TestZoomViewController4: UIViewController, ZoomTransitionable {
    private let testButton = UIButton(type: .system)

    // ZoomTransitionable
    var zoomSourceView: UIView? { testButton }

    private var testDelegate: UIViewControllerTransitioningDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        testButton.setTitle("Zoom Present", for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        testButton.backgroundColor = .red
        testButton.setTitleColor(.white, for: .normal)
        testButton.layer.cornerRadius = 12

        view.addSubview(testButton)
        
        testDelegate = CustomZoomTransition(referenceView: testButton)
        
        testButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.height.equalTo(56)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        testButton.addAction(UIAction { [weak self] _ in
            self?.presentNext()
        }, for: .touchUpInside)
    }

    private func presentNext() {
        let vc = TestZoomNextViewController()
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self.testDelegate
        vc.view.backgroundColor = .red
        self.present(vc, animated: true)
    }
}



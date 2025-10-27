//
//  TestZoomViewController3.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/27/25.
//

import UIKit
import SnapKit

// WWDC 2024 iOS 18+
// https://developer.apple.com/videos/play/wwdc2024/10145/?time=182
/// @available(iOS 18.0, *)
/// open var preferredTransition: UIViewController.Transition?
final class TestZoomViewController3: UIViewController {
    private let testButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        testButton.backgroundColor = .red
        testButton.layer.cornerRadius = 12

        view.addSubview(testButton)
        testButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.height.equalTo(56)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        testButton.addAction(UIAction { [weak self] _ in
            self?.nextView()
        }, for: .touchUpInside)
    }

    private func nextView() {
        let vc = TestZoomNextViewController()
        if #available(iOS 18.0, *) {
            vc.preferredTransition = .zoom { [weak self] context in
                guard let self else { return nil }
                return testButton
            }
        }
        
        self.present(vc, animated: true)
    }
}

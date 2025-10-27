//
//  TestZoomViewController2.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/27/25.
//

//import UIKit
//import SnapKit
// import Hero
/*
 너무 다 별로다.
 */
//
//final class TestZoomViewController2: UIViewController {
//    
//    private let testButton = UIButton().after {
//        $0.backgroundColor = .red
//    }
//    
//    override func viewDidLoad() {
//        view.backgroundColor = .white
//        view.addSubview(testButton)
//        self.hero.isEnabled = true
//        testButton.snp.makeConstraints { make in
//            make.top.equalTo(view.safeAreaLayoutGuide)
//            make.horizontalEdges.equalToSuperview().inset(20)
//        }
//        
//        testButton.addAction(UIAction(handler: { [weak self] _ in
//            self?.nextView()
//        }), for: .touchUpInside)
//        
//        
//        
//    }
//}
//
//extension TestZoomViewController2 {
//    private func nextView() {
//        let vc = TestZoomNextViewController()
//        vc.hero.isEnabled = true
////        vc.modalPresentationStyle = .custom
//        
//        self.hero.modalAnimationType = .selectBy(presenting: .zoom, dismissing: .zoomOut)
//        self.present(vc, animated: true)
//        
////        self.navigationController?.pushViewController(vc, animated: true)
//    }
//}

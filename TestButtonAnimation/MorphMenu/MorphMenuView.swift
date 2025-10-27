//
//  MorphMenuView.swift
//  TestButtonAnimation
//
//  Created by Jae hyung Kim on 10/24/25.
//

import UIKit
import SnapKit

protocol MorphMenuViewDelegate: AnyObject {
    func morphMenuViewDidOpen(_ view: MorphMenuView)
    func morphMenuViewDidClose(_ view: MorphMenuView)
    func morphMenuView(_ view: MorphMenuView, didSelectItemAt index: Int)
}

final class MorphMenuView: BaseView {
    
    /// 딤처리 뷰
    private let dimmingView = UIView().after {
        $0.backgroundColor = .gray.withAlphaComponent(0.3)
        $0.alpha = 0
        $0.isHidden = true
    }
    /// 버튼 텍스트
    private let buttonLabel: UILabel = UILabel().after {
        $0.text = "열기"
        $0.font = .systemFont(ofSize: 20, weight: .bold)
        $0.textColor = .brown
    }
    /// 버튼 <-> 메뉴 변신 뷰
    private let morphMenuControl: UIControl = UIControl().after {
        $0.backgroundColor = .black
        $0.layer.cornerCurve = .continuous
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowRadius = 8
        $0.layer.shadowOffset = CGSize(width: 0, height: 4)
    }
    /// 펼침 상태 컨텐츠
    private let contentStackView: UIStackView = UIStackView().after {
        $0.axis = .vertical
        $0.alignment = .fill
        $0.distribution = .fill
        $0.spacing = 8
        $0.isLayoutMarginsRelativeArrangement = true
        $0.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        $0.isHidden = true
        $0.alpha = 0
    }
    
    private var isExpanded = false
    private var controlSize: CGSize = .zero {
        didSet {
            let circleValue = findCircleValue(size: controlSize)
            morphMenuControl.layer.cornerRadius = circleValue
        }
    }
    private var buttonContent: Constraint?
    private var contentStackViewConstraint: Constraint?
    
    // MARK: Gestures
    private lazy var tap: UITapGestureRecognizer = {
        let gr = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gr.cancelsTouchesInView = false
        return gr
    }()
    private lazy var dimTap: UITapGestureRecognizer = {
        let gr = UITapGestureRecognizer(target: self, action: #selector(handleDimTap(_:)))
        gr.cancelsTouchesInView = true
        return gr
    }()
    
    private lazy var longPress: UILongPressGestureRecognizer = {
        let gr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gr.minimumPressDuration = 0.15
        gr.cancelsTouchesInView = false
        return gr
    }()
    
    weak var delegate: MorphMenuViewDelegate? = nil
    
    // MARK: Layouts
    override func setHierarchy() {
        self.addSubview(dimmingView)
        self.addSubview(morphMenuControl)
        morphMenuControl.addSubview(buttonLabel)
        morphMenuControl.addSubview(contentStackView)
        
        setupMenuItems()
        
        setActions()
    }
    
    override func setLayoutConstraints() {
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        morphMenuControl.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(20)
            make.trailing.equalToSuperview().inset(20)
        }
        
        buttonLabel.snp.makeConstraints { make in
            buttonContent = make.edges.equalToSuperview().inset(14).constraint
        }
        buttonContent?.activate()
        
        contentStackView.snp.makeConstraints { make in
            contentStackViewConstraint = make.edges.equalToSuperview().constraint
        }
        contentStackViewConstraint?.deactivate()
        
        reSizeButton()
    }
    
    private func setActions() {
        morphMenuControl.addGestureRecognizer(longPress)
        morphMenuControl.addGestureRecognizer(tap)
        dimmingView.addGestureRecognizer(dimTap)
    }
    
    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        guard !isExpanded else { return }
        switch gr.state {
        case .began:
            let h = UIImpactFeedbackGenerator(style: .light)
            h.impactOccurred()
            
            UIView.animate(withDuration: 0.13) { [weak self] in
                self?.morphMenuControl.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
                self?.morphMenuControl.layer.shadowOpacity = 0.28
                self?.morphMenuControl.layer.shadowRadius = 10
            }
            
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.13) { [weak self] in
                self?.morphMenuControl.transform = .identity
                self?.morphMenuControl.layer.shadowOpacity = 0.20
                self?.morphMenuControl.layer.shadowRadius = 8
            }
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gr: UITapGestureRecognizer) {
        if gr.state == .ended {
            isExpanded ? collapse() : expand()
        }
    }

    @objc private func handleDimTap(_ gr: UITapGestureRecognizer) {
        if gr.state == .ended {
            collapse()
        }
    }

    private func expand() {
        guard !isExpanded else { return }
        isExpanded = true
        dimmingView.isHidden = false

        morphMenuControl.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(40)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
        }
        
        buttonContent?.deactivate()
        contentStackViewConstraint?.activate()
        
        
        self.contentStackView.isHidden = false

        let h = UIImpactFeedbackGenerator(style: .light)
        h.impactOccurred()

        UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.4, options: [.curveEaseInOut]) { [weak self] in
            guard let self = self else { return }
            self.dimmingView.alpha = 1
            self.morphMenuControl.layer.cornerRadius = 20
            self.contentStackView.alpha = 1
            self.buttonLabel.alpha = 0
            self.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.morphMenuViewDidOpen(self)
        }
    }

    private func collapse() {
        guard isExpanded else { return }
        isExpanded = false

        morphMenuControl.snp.remakeConstraints { make in
            make.bottom.equalToSuperview().inset(20)
            make.trailing.equalToSuperview().inset(20)
        }
        
        contentStackViewConstraint?.deactivate()
        buttonContent?.activate()

        UIView.animate(withDuration: 0.26, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0.6, options: [.curveEaseInOut]) { [weak self] in
            guard let self = self else { return }
            self.dimmingView.alpha = 0
            self.reSizeButton()
            self.buttonLabel.alpha = 1
            self.contentStackView.alpha = 0
            self.layoutIfNeeded()
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.contentStackView.isHidden = true
            self.dimmingView.isHidden = true
            self.delegate?.morphMenuViewDidClose(self)
        }
    }
    
    private func setupMenuItems() {
        let titles = ["테스트1", "테스트2", "테스트3"]
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.contentHorizontalAlignment = .leading
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            button.tag = index
            button.addTarget(self, action: #selector(handleItemTap(_:)), for: .touchUpInside)
            
            
            let bg = UIView()
            bg.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            bg.layer.cornerRadius = 10
            bg.layer.cornerCurve = .continuous
            bg.translatesAutoresizingMaskIntoConstraints = false
            bg.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            
            button.snp.makeConstraints { make in
                make.horizontalEdges.equalToSuperview().inset(12)
                make.verticalEdges.equalToSuperview().inset(10)
            }
            
            contentStackView.addArrangedSubview(bg)
        }
    }

    @objc private func handleItemTap(_ sender: UIButton) {
        delegate?.morphMenuView(self, didSelectItemAt: sender.tag)
        collapse()
    }
}

extension MorphMenuView {
    private func reSizeButton() {
        buttonLabel.sizeToFit()
        morphMenuControl.layoutIfNeeded()
        morphMenuControl.sizeToFit()
        self.controlSize = morphMenuControl.frame.size
    }
    
    private func findCircleValue(size: CGSize) -> CGFloat {
        let minDimension = min(size.width, size.height)
        return minDimension / 2
    }
}

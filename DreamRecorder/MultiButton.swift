//
//  MultipleButton.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 9..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

protocol MultiButtonDelegate: NSObjectProtocol {
    func multipleButton(_: MultiButton, didButtonTap button: UIButton, at index: Int)
}

@IBDesignable
class MultiButton: UIStackView {
    
    // MARK: Properties.
    // IBInspectable Vriables.
    @IBInspectable var numberOfButton: Int = 7 {
        didSet {
            self.setupButtons()
        }
    }
    @IBInspectable var buttonBackgroundColor: UIColor = UIColor.white {
        didSet {
            for button in self.buttons {
                button.backgroundColor = buttonBackgroundColor
            }
        }
    }
    @IBInspectable var buttonTitleColor: UIColor = UIColor.black {
        didSet {
            for button in self.buttons {
                button.setTitleColor(buttonTitleColor, for: .normal)
            }
        }
    }
    @IBInspectable var buttonTitleColorHighlighted: UIColor = UIColor.gray {
        didSet {
            for button in self.buttons {
                button.setTitleColor(buttonTitleColorHighlighted, for: .highlighted)
                button.setTitleColor(buttonTitleColorHighlighted, for: .selected)
            }
        }
    }
    
    // Properties.
    var delegate: MultiButtonDelegate?
    private var buttons: [UIButton] = []
    
    // MARK: Initializer.
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupDefaultProperties()
        self.setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.setupDefaultProperties()
        self.setupButtons()
    }
    
    // MARK: Private Functions.
    private func setupDefaultProperties(){
        self.axis = .horizontal
        self.distribution = .fillEqually
        self.alignment = .fill
    }
    
    private func setupButtons(){
        
        for button in self.buttons {
            self.removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        self.buttons.removeAll()
        
        for index in 0 ..< self.numberOfButton {
            let newButton = UIButton()
            self.buttons.append(newButton)
            newButton.setTitle("\(index)", for: .normal)
            newButton.tag = index
            newButton.addTarget(self, action: #selector(self.buttonDidTouchUpInside(sender:)), for: .touchUpInside)
            self.addArrangedSubview(newButton)
        }
    }
    
    @objc private func buttonDidTouchUpInside(sender: UIButton) {
        self.delegate?.multipleButton(self, didButtonTap: sender, at: sender.tag)
    }
    
    // MARK: Public functions.
    func setTitles(titles: String...){
        guard titles.count == self.buttons.count else { return }
        for (index, title) in titles.enumerated() {
            self.buttons[index].setTitle(title, for: .normal)
        }
    }
    
    func setTitles(titles: [String]) {
        guard titles.count == self.buttons.count else { return }
        for (index, title) in titles.enumerated() {
            self.buttons[index].setTitle(title, for: .normal)
            self.buttons[index].titleLabel?.font = UIFont.preferredFont(forTextStyle: .caption2)
        }
    }
    
    func setAttributedTitles(attributedString: NSAttributedString){
        for button in self.buttons {
            button.setAttributedTitle(attributedString, for: .normal)
        }
    }
    
    func setButtonsEnabled(to: Bool) {
        for button in self.buttons {
            button.isEnabled = to
        }
    }
    
    func setSelection(options: WeekdayOptions) {
        for button in self.buttons {
            button.isSelected = false
        }
        if options.contains(.mon) { self.buttons[1].isSelected = true }
        if options.contains(.tue) { self.buttons[2].isSelected = true }
        if options.contains(.wed) { self.buttons[3].isSelected = true }
        if options.contains(.thu) { self.buttons[4].isSelected = true }
        if options.contains(.fri) { self.buttons[5].isSelected = true }
        if options.contains(.sat) { self.buttons[6].isSelected = true }
        if options.contains(.sun) { self.buttons[0].isSelected = true }
    }
}

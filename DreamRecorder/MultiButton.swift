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
    
    // MARK: - Properties.
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
    
    // - Internal.
    var delegate: MultiButtonDelegate?
    
    // - Private.
    fileprivate var buttons: [UIButton] = []
    /// MultiButton은 버튼을 클릭할 수 있는 모드와 클릭할 수 없이 Label용도로만 쓰이는 두가지 상태가 존재한다.
    /// if ture - button역할 - 각 버튼 클릭 O, Accessibility접근 X (각각의 버튼이 Accessibility)
    /// if false - Label역할 - 각 버튼 클릭 X, Accessibility접근 O (Button묶음 StackView가 Accessibility)
    fileprivate var canSelectButton = true
    
    // MARK: - Initializer.
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
    
    // MARK: - Private Methods.
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
            newButton.setTitle("\(index)", for: .normal)
            newButton.tag = index
            newButton.addTarget(self, action: #selector(self.buttonDidTouchUpInside(sender:)), for: .touchUpInside)
            newButton.titleLabel?.adjustsFontSizeToFitWidth = true
            
            self.buttons.append(newButton)
            self.addArrangedSubview(newButton)
        }
    }
    
    @objc private func buttonDidTouchUpInside(sender: UIButton) {
        self.delegate?.multipleButton(self, didButtonTap: sender, at: sender.tag)
    }
    
    // MARK: Public Methods.
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
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        var shouldVeryShort = false
        
        for (index, button) in self.buttons.enumerated() {
            guard let titleString = button.titleLabel?.text as? NSString,
                let titleLabel = button.titleLabel
            else {
                continue
            }
            
            let size = titleString.size(attributes: [NSFontAttributeName: titleLabel.font])
            if button.frame.size.width < size.width {
                shouldVeryShort = true
            }
        }
        
        if shouldVeryShort {
            for (index, button) in self.buttons.enumerated() {
                button.titleLabel?.text = Calendar.current.veryShortWeekdaySymbols[index]
            }
        }
        
    }
    
    func setButtonsEnabled(to: Bool) {
        self.canSelectButton = to
        for button in self.buttons {
            button.isAccessibilityElement = to
        }
    }
    
    func setFonts(to font: UIFont) {
        for button in self.buttons {
            button.titleLabel?.font = font
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        /// UIButton.enabled로 하면 button의 textLabel의 색상이 무조건 enabled 색으로 설정된다.
        /// 하지만 Label용도로 쓰이더라도 Highlight와 Normal상태의 색상을 구분하기 위해서는 enable말고
        /// hitTest를 통해서 Action이 일어남을 방지함과 동시에 Cell에서는 해당 버튼이 눌리더라도
        /// 셀을 누르는 것처럼(Label로 만들때와 같은 모습)으로 만들어 준다.
        guard self.canSelectButton else { return nil }
        return super.hitTest(point, with: event)
    }
}

// Extension for MultiButton as WeekdayButton.
extension MultiButton {
    
    override var accessibilityLabel: String? {
        set {
            self.accessibilityLabel = newValue
        }
        get {
            
            var weekdayOptions: WeekdayOptions = .none
            var selectedIndexs: [Int] = []
            
            for (index, button) in self.buttons.enumerated() {
                if button.isSelected {
                    let newWeekdayOption = WeekdayOptions(rawValue: 1 << index)
                    weekdayOptions.insert(newWeekdayOption)
                    
                    selectedIndexs.append(index)
                }
            }
            switch weekdayOptions {
            case WeekdayOptions.none:
                return "Once.".localized
            case WeekdayOptions.weekdays:
                return "Repeat Weekday.".localized
            case WeekdayOptions.weekend:
                return "Repeat Weekend.".localized
            case WeekdayOptions.all:
                return "Repeat every day.".localized
            default:
                var resultString = "Repeat.".localized
                
                for index in selectedIndexs {
                    resultString += Calendar.current.weekdaySymbols[index] + ","
                }
                return resultString
            }
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

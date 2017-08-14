//
//  DreamListCell.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 13..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

enum CellSide : Int {
    case left = 0
    case right = 1
}

extension Array {
    subscript(side : CellSide) -> Element {
        get {
            return self[side.rawValue]
        }
    }
}

class DreamListCell: UITableViewCell {
    
    struct NotificationName {
        static let cellClose = Foundation.Notification.Name("cellClose")
    }
    
    let maxCellCloseMillSeconds : CGFloat = 300
    let cellOpenVelocityThreshold : CGFloat = 0.6
    
    var scrollView : SwipeableScrollView!
    var buttonViews : [UIView]!
    var scrollViewContentView : UIView!
    
    //MARK:- Life Cycle
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setUp()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setUp()
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(open(_:)))
        swipeLeft.direction = .left
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(open(_:)))
        swipeRight.direction = .right
        
        self.addGestureRecognizer(swipeLeft)
        self.addGestureRecognizer(swipeRight)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.setUp()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state

    }
    
    //MARK:- Class Method
    
    func closeAllCells() {
        self.closeAllCellsExcept(cell: nil)
    }
    
    func closeAllCellsExcept(cell : DreamListCell?) {
        NotificationCenter.default.post(name: NotificationName.cellClose, object: cell)
    }

    //MARK:- Public Property 
    
    var closed : Bool {
        return __CGPointEqualToPoint(self.scrollView.contentOffset, .zero)
    }
    
    var leftInset : CGFloat {
        return self.buttonViews[CellSide.left].frame.width
    }
    
    var rightInset : CGFloat {
        return self.buttonViews[CellSide.right].frame.width
    }
    
    //MARK:- Public Method
    
    func close() {
        self.scrollView.setContentOffset(.zero, animated: true)
    }
    
    
    func open(_ gesture : UISwipeGestureRecognizer) {
        if gesture.direction == UISwipeGestureRecognizerDirection.left {
            self.open(side: .right, animated: true)
        } else if gesture.direction == UISwipeGestureRecognizerDirection.right {
            self.open(side: .left, animated: true)
        }
    }
    
    func open(side : CellSide, animated animate : Bool) {
        self.closeAllCellsExcept(cell: self)
        
        switch side {
        case .left:
            self.scrollView.setContentOffset(CGPoint(x: -self.leftInset, y: 0), animated: animate)
        case .right:
            self.scrollView.setContentOffset(CGPoint(x: self.rightInset, y: 0), animated: animate)
        }
        
    }
    
    func createButton(with width: CGFloat, side: CellSide) -> UIButton {
        let container = buttonViews[side]
        let size = container.bounds.size
        
        let button = UIButton(type: .custom)
        button.autoresizingMask = .flexibleHeight
        button.frame = CGRect(x: size.width, y: 0, width: width, height: size.height)
        
        //Resize the container to fit the new button.
        var x : CGFloat
        
        switch side {
        case .left:
            x = -(width + size.width)
        case .right:
            x = self.contentView.bounds.width
        }
        
        container.frame = CGRect(x: x, y: 0, width: width, height: size.height)
        container.addSubview(button)
        self.scrollView.contentInset = UIEdgeInsetsMake(0, self.leftInset, 0, self.rightInset)
        
        return button
    }

    
    //MARK:- private method
    
    
    @objc private func handleCloseEvent(_ notification : Notification) {
        let object = notification.object as? DreamListCell
        
        if(object == self) {
            return
        }
        
        self.close()
    }
    
    private func createButtonView() -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: self.contentView.bounds.height))
        view.autoresizingMask = [.flexibleHeight]
        self.scrollView.addSubview(view)
        return view
    }


    private func setUp() {
        
        self.scrollView = SwipeableScrollView(frame: self.bounds)
        self.scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.scrollView.contentSize = self.bounds.size
        self.scrollView.contentInset = UIEdgeInsetsMake(0, 160, 0, 0)
        self.scrollView.customDelegate = self
        self.scrollView.delegate = self
        self.scrollView.scrollsToTop = false;
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.showsHorizontalScrollIndicator = false
        self.contentView.addSubview(scrollView)
        
        self.buttonViews = [self.createButtonView(), self.createButtonView()]
        
        self.scrollViewContentView = UIView(frame: scrollView.bounds)
        scrollViewContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollViewContentView.backgroundColor = UIColor.white
        self.scrollView.addSubview(scrollViewContentView)
        
        
        let label = UILabel(frame: contentView.bounds.insetBy(dx: 10, dy: 0))
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        label.text = "Test"
        
        scrollViewContentView.addSubview(label)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleCloseEvent(_:)),
                                               name: NotificationName.cellClose,
                                               object: nil)
        

    }
    
    //MARK:- UIView
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.scrollView.contentSize = self.contentView.bounds.size
        self.scrollView.contentOffset = .zero
    }
    
    //MARKL= UIResponder
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundView?.backgroundColor = .gray
        } else {
            self.backgroundView?.backgroundColor = .white
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.closeAllCells()
        super.touchesBegan(touches, with: event)
    }

}

extension DreamListCell: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if (self.leftInset == 0 && scrollView.contentOffset.x < 0) || (self.rightInset == 0 && scrollView.contentOffset.x > 0) {
            scrollView.contentOffset = .zero
        }
        
        let leftView = self.buttonViews[CellSide.left]
        let rightView = self.buttonViews[CellSide.right]
        
        if scrollView.contentOffset.x < 0 {
            leftView.frame = CGRect(x: scrollView.contentOffset.x, y: 0, width: self.leftInset, height: leftView.frame.size.height)
            leftView.isHidden = false
            rightView.isHidden = true
        } else if scrollView.contentOffset.x > 0 {
            rightView.frame = CGRect(x: self.contentView.bounds.size.width - self.rightInset + scrollView.contentOffset.x , y: 0, width: self.rightInset, height: rightView.frame.size.height)
            rightView.isHidden = false
            leftView.isHidden = true
        } else {
            leftView.isHidden = true
            rightView.isHidden = true
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.closeAllCellsExcept(cell: self)
    }
    

    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let x = scrollView.contentOffset.x, left = self.leftInset, right = self.rightInset
        
        if left > 0 && (x < -left || (x < 0 && velocity.x < -cellOpenVelocityThreshold)) {
            targetContentOffset.pointee.x = -left
        } else if right > 0 && (x > right || (x > 0 && velocity.x > cellOpenVelocityThreshold)) {
            targetContentOffset.pointee.x = right
        } else {
            targetContentOffset.pointee = .zero
            
            //If the scroll isn't on a fast path to zero, animate it instead.
            let ms = x / -velocity.x
            if velocity.x == 0 || ms < 0 || ms > maxCellCloseMillSeconds {
                DispatchQueue.main.async {
                    self.scrollView.setContentOffset(.zero, animated: true)
                }
            }
        }
    }
    
    

}

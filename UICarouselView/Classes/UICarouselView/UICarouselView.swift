//
//  UICarouselView.swift
//  UICarouselView
//
//  Created by Zhang You Jun on 2018/9/29.
//
import Foundation
import QuartzCore
import UIKit

public enum iCarouselType : Int {
    case linear = 0
    case rotary
    case invertedRotary
    case cylinder
    case invertedCylinder
    case wheel
    case invertedWheel
    case coverFlow
    case coverFlow2
    case timeMachine
    case invertedTimeMachine
    case custom
}

@objc public enum iCarouselOption : Int {
    case wrap = 0
    case showBackfaces
    case offsetMultiplier
    case visibleItems
    case count
    case arc
    case angle
    case radius
    case tilt
    case spacing
    case fadeMin
    case fadeMax
    case fadeRange
    case fadeMinAlpha
}

@objc public protocol iCarouselDataSource: NSObjectProtocol {
    func numberOfItems(in carousel: iCarousel?) -> Int
    
    func carousel(_ carousel: iCarousel?, viewForItemAt index: Int, reusing view: UIView?) -> UIView?
    
    @objc optional func numberOfPlaceholders(in carousel: iCarousel?) -> Int
    
    @objc optional func carousel(_ carousel: iCarousel?, placeholderViewAt index: Int, reusing view: UIView?) -> UIView?
}

@objc public protocol iCarouselDelegate: NSObjectProtocol {
    @objc optional func carouselWillBeginScrollingAnimation(_ carousel: iCarousel?)
    
    @objc optional func carouselDidEndScrollingAnimation(_ carousel: iCarousel?)
    
    @objc optional func carouselDidScroll(_ carousel: iCarousel?)
    
    @objc optional func carouselCurrentItemIndexDidChange(_ carousel: iCarousel?)
    
    @objc optional func carouselWillBeginDragging(_ carousel: iCarousel?)
    
    @objc optional func carouselDidEndDragging(_ carousel: iCarousel?, willDecelerate decelerate: Bool)
    
    @objc optional func carouselWillBeginDecelerating(_ carousel: iCarousel?)
    
    @objc optional func carouselDidEndDecelerating(_ carousel: iCarousel?)
    
    @objc optional func carousel(_ carousel: iCarousel?, shouldSelectItemAt index: Int) -> Bool
    
    @objc optional func carousel(_ carousel: iCarousel?, didSelectItemAt index: Int)
    
    @objc optional func carouselItemWidth(_ carousel: iCarousel?) -> CGFloat
    
    @objc optional func carousel(_ carousel: iCarousel?, itemTransformForOffset offset: CGFloat, baseTransform transform: CATransform3D) -> CATransform3D
    
    @objc optional func carousel(_ carousel: iCarousel?, valueFor option: iCarouselOption, withDefault value: CGFloat) -> CGFloat
}


public class iCarousel: UIView {
    
    public var dataSource: iCarouselDataSource?{
        didSet{
            if oldValue !== dataSource, let _ = dataSource {
                reloadData()
            }
        }
    }
    public var delegate: iCarouselDelegate?{
        didSet{
            if oldValue !== delegate, let _ = delegate ,let _ = dataSource {
                setNeedsLayout()
            }
        }
    }
    public var type: iCarouselType = .linear{
        didSet{
            if oldValue != type {
                layOutItemViews()
            }
        }
    }
    
    public var perspective: CGFloat = 0.0{
        didSet{
            transformItemViews()
        }
    }
    public var decelerationRate: CGFloat = 0.0
    public var scrollSpeed: CGFloat = 0.0
    public var bounceDistance: CGFloat = 0.0
    public var scrollEnabled = false
    public var pagingEnabled = false
    
    public var vertical = false {
        didSet{
            if vertical != oldValue {
                layOutItemViews()
            }
        }
    }
    private(set) var wrapEnabled = false
    public var bounces = false
    public var scrollOffset: CGFloat = 0.0 {
        willSet{
            scrolling = false
            decelerating = false
            startOffset = newValue
            endOffset = newValue
        }
        didSet{
            if fabs(Float(oldValue - scrollOffset)) > 0.0 {
                depthSortViews()
                didScroll()
            }else {
                self.scrollOffset = oldValue
            }
        }
    }
    
    private(set) var offsetMultiplier: CGFloat = 0.0
    public var contentOffset = CGSize.zero {
        didSet{
            if oldValue != contentOffset {
                layOutItemViews()
            }
        }
    }
    
    public var viewpointOffset = CGSize.zero {
        didSet{
            if oldValue != viewpointOffset {
                transformItemViews()
            }
        }
    }
    private(set) var numberOfItems: Int = 0
    private(set) var numberOfPlaceholders: Int = 0
    
    public var currentItemIndex: Int = 0 {
        didSet{
            self.scrollOffset = CGFloat(currentItemIndex)
        }
    }
    
    public var currentItemView: UIView?{
        return itemView(at: currentItemIndex)
    }
    public var indexesForVisibleItems: [AnyHashable ]{
        return itemViews.keys.sorted(by:#selector(self.compare(_:)))
    }
    public private(set) var numberOfVisibleItems: Int = 0
    public var visibleItemViews: [UIView]{
        return itemViews.
        //    return itemViews.objects(forKeys: indexesForVisibleItems, notFoundMarker: NSNull())
    }
    public private(set) var itemWidth: CGFloat = 0.0
    public private(set) var contentView: UIView?
    public private(set) var toggle: CGFloat = 0.0
    public var autoscroll: CGFloat = 0.0 {
        didSet{
            if autoscroll != 0.0 {
                startAnimation()
            }
        }
    }
    public var stopAtItemBoundary = false
    public var scrollToItemBoundary = false
    public var ignorePerpendicularSwipes = false
    public var centerItemWhenSelected = false
    public private(set) var dragging = false
    public private(set) var decelerating = false
    public  private(set) var scrolling = false
    private var itemViews: [AnyHashable : UIView] = [:]
    private var itemViewPool: Set<UIView> = []
    private var placeholderViewPool: Set<UIView> = []
    private var previousScrollOffset: CGFloat = 0.0
    private var previousItemIndex: Int = 0
    private var numberOfPlaceholdersToShow: Int = 0
    private var startOffset: CGFloat = 0.0
    private var endOffset: CGFloat = 0.0
    private var scrollDuration: TimeInterval = 0.0
    private var startTime: TimeInterval = 0.0
    private var lastTime: TimeInterval = 0.0
    private var startVelocity: CGFloat = 0.0
    private var timer: Timer?
    private var previousTranslation: CGFloat = 0.0
    private var didDrag = false
    private var toggleTime: TimeInterval = 0.0
    
    //MARK: init
    func setUp() {
        decelerationRate = 0.95
        scrollEnabled = true
        bounces = true
        offsetMultiplier = 1.0
        perspective = -1.0 / 500.0
        contentOffset = CGSize.zero
        viewpointOffset = CGSize.zero
        scrollSpeed = 1.0
        bounceDistance = 1.0
        stopAtItemBoundary = true
        scrollToItemBoundary = true
        ignorePerpendicularSwipes = true
        centerItemWhenSelected = true
        
        contentView = UIView(frame: bounds)
        
        contentView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        //add pan gesture recogniser
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.didPan(_:)))
        panGesture.delegate = self as? UIGestureRecognizerDelegate?
        contentView.addGestureRecognizer(panGesture)
        
        //add tap gesture recogniser
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTap(_:)))
        tapGesture.delegate = self as? UIGestureRecognizerDelegate?
        contentView.addGestureRecognizer(tapGesture)
        
        //set up accessibility
        accessibilityTraits = UIAccessibilityTraitAllowsDirectInteraction
        isAccessibilityElement = true
        
        addSubview(contentView!)
        if let _ = dataSource {
            reloadData()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
        if let _ = superview {
            startAnimation()
        }
        
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
        
    }
    
    deinit {
        stop()
    }
    
    func pushAnimationState(_ enabled: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(!enabled)
    }
    
    func popAnimationState() {
        CATransaction.commit()
    }
    
    //MARK: view management
    
    //
    //    func itemView(at index: Int) -> UIView? {
    //        return itemViews[index]
    //    }
    //
    //
    //
    //    func indexOfItemView(_ view: UIView?) -> Int {
    //        var index: Int? = nil
    //        if let aView = view {
    //            index = (itemViews.allValues as NSArray).index(of: aView)
    //        }
    //        if index != NSNotFound {
    //            return Int(itemViews.keys[index ?? 0])
    //        }
    //        return NSNotFound
    //    }
    //
    //    func indexOfItemViewOrSubview(_ view: UIView?) -> Int {
    //        let index: Int = indexOfItemView(view)
    //        if index == NSNotFound && view?.superview != nil && view != contentView {
    //            return indexOfItemViewOrSubview(view?.superview as? UIView)
    //        }
    //        return index
    //    }
    //
    //    func itemView(at point: CGPoint) -> UIView? {
    //        for view: UIView? in  {
    //
    //        }
    //        itemViews.allValues
    //        compareViewDepth
    //    }
    //
    //
    //
    //
    func scroll(byOffset offset: CGFloat, duration: TimeInterval) {
    }
    
    func scroll(toOffset offset: CGFloat, duration: TimeInterval) {
    }
    
    func scroll(byNumberOfItems itemCount: Int, duration: TimeInterval) {
    }
    
    func scrollToItem(at index: Int, duration: TimeInterval) {
    }
    
    func scrollToItem(at index: Int, animated: Bool) {
    }
    //
    //    func itemView(at index: Int) -> UIView? {
    //    }
    //
    //    func indexOfItemView(_ view: UIView?) -> Int {
    //    }
    //
    //    func indexOfItemViewOrSubview(_ view: UIView?) -> Int {
    //    }
    //
    //    func offsetForItem(at index: Int) -> CGFloat {
    //    }
    //
    //    func itemView(at point: CGPoint) -> UIView? {
    //    }
    
    func removeItem(at index: Int, animated: Bool) {
    }
    
    func insertItem(at index: Int, animated: Bool) {
    }
    
    func reloadItem(at index: Int, animated: Bool) {
    }
    
    func reloadData() {
    }
    
    func layOutItemViews() {
        
        guard let dataSource = dataSource, let contentView = contentView else {
            return
        }
        
        //update wrap
        switch type {
        case .rotary, .invertedRotary, .cylinder , .invertedCylinder, .wheel, .invertedWheel:
            wrapEnabled = true
        case .coverFlow, .coverFlow2, .timeMachine, .invertedTimeMachine, .linear, .custom:
            wrapEnabled = false
        }
        
        wrapEnabled = !(value(for: .wrap, withDefault: wrapEnabled ? 1 : 0) == 0)
        
        //no placeholders on wrapped carousels
        numberOfPlaceholdersToShow = wrapEnabled ? 0 : numberOfPlaceholders
        
        //set item width
        updateItemWidth()
        
        //update number of visible items
        updateNumberOfVisibleItems()
        
        //prevent false index changed event
        previousScrollOffset = scrollOffset
        
        //update offset multiplier
        switch type {
        case .coverFlow2, .coverFlow:
            offsetMultiplier = 2.0
        case .cylinder, .invertedCylinder, .wheel, .invertedWheel, .rotary, .invertedRotary, .timeMachine, .invertedTimeMachine, .linear ,.custom:
            offsetMultiplier = 1.0
            
        }
        offsetMultiplier = value(for: .offsetMultiplier, withDefault: offsetMultiplier)
        
        //align
        if !scrolling && !decelerating && autoscroll != 0.0 {
            if scrollToItemBoundary && currentItemIndex != -1 {
                scrollToItem(atIndex: currentItemIndex, animated: true)
            } else {
                scrollOffset = clampedOffset(scrollOffset)
            }
        }
        didScroll()
    }
    
    func value(for option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        return delegate?.carousel?(self, valueFor: option, withDefault: value) ?? value
    }
    
    func updateItemWidth() {
        itemWidth = delegate?.carouselItemWidth?(self) ?? itemWidth
        if numberOfItems > 0 {
            if itemViews.isEmpty {
                loadView(at: 0)
            }
        } else if numberOfPlaceholders > 0 {
            if itemViews.isEmpty {
                loadView(at: -1)
            }
        }
    }
    
    func loadView(at index: Int, withContainerView containerView: UIView?) -> UIView? {
        pushAnimationState(false)
        
        var view: UIView?
        if index < 0 {
            view = dataSource?.carousel?(self, placeholderViewAt: Int(ceil(CGFloat(numberOfPlaceholdersToShow) / 2.0)) + index, reusingView: dequeuePlaceholderView())
        } else if index >= numberOfItems {
            view = dataSource.carousel(self, placeholderViewAtIndex: numberOfPlaceholdersToShow / 2.0 + Double(index) - numberOfItems, reusingView: dequeuePlaceholderView())
        } else {
            view = dataSource.carousel(self, viewForItemAt: index, reusingView: dequeueItemView())
        }
        
        if view == nil {
            view = UIView()
        }
        
        setItemView(view, for: index)
        if containerView != nil {
            //get old item view
            let oldItemView: UIView? = containerView?.subviews.last
            if index < 0 || index >= numberOfItems {
                queuePlaceholderView(oldItemView)
            } else {
                queueItemView(oldItemView)
            }
            
            //set container frame
            var frame: CGRect? = containerView?.bounds
            if vertical {
                frame?.size.width = view.frame.size.width
                frame?.size.height = min(itemWidth, view.frame.size.height)
            } else {
                frame?.size.width = min(itemWidth, view.frame.size.width)
                frame?.size.height = view.frame.size.height
            }
            containerView?.bounds = frame ?? CGRect.zero
            
            
            
            //set view frame
            frame = view.frame
            frame?.origin.x = ((containerView?.bounds.size.width ?? 0.0) - (frame?.size.width ?? 0.0)) / 2.0
            frame?.origin.y = ((containerView?.bounds.size.height ?? 0.0) - (frame?.size.height ?? 0.0)) / 2.0
            view.frame = frame
            
            //switch views
            oldItemView?.removeFromSuperview()
            containerView?.addSubview(view)
        } else {
            contentView.addSubview(containView(view))
        }
        view.superview.layer.opacity = 0.0
        transformItemView(view, at: index)
        
        popAnimationState()
        
        return view
    }
    
    func loadView(at index: Int) -> UIView? {
        return loadView(at: index, withContainerView: nil)
    }
    
    func dequeuePlaceholderView() -> UIView? {
        if let view = placeholderViewPool.popFirst() {
            return view
        }
        return .none
    }
    
    func dequeueItemView() -> UIView? {
        if let view = itemViewPool.popFirst() {
            return view
        }
        return .none
    }
    
}

let MIN_TOGGLE_DURATION = 0.2
let MAX_TOGGLE_DURATION = 0.4
let SCROLL_DURATION = 0.4
let INSERT_DURATION = 0.4
let DECELERATE_THRESHOLD = 0.1
let SCROLL_SPEED_THRESHOLD = 2.0
let SCROLL_DISTANCE_THRESHOLD = 0.1
let DECELERATION_MULTIPLIER = 30.0
let FLOAT_ERROR_MARGIN = 0.000001
let MAX_VISIBLE_ITEMS = 30


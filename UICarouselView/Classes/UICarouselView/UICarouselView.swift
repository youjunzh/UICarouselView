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
//                layOutItemViews()
            }
        }
    }
    
    public var perspective: CGFloat = 0.0{
        didSet{
//            transformItemViews()
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
//                layOutItemViews()
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
//                depthSortViews()
//                didScroll()
            }else {
                self.scrollOffset = oldValue
            }
        }
    }
    
    private(set) var offsetMultiplier: CGFloat = 0.0
    public var contentOffset = CGSize.zero {
        didSet{
            if oldValue != contentOffset {
//                layOutItemViews()
            }
        }
    }
    
    public var viewpointOffset = CGSize.zero {
        didSet{
            if oldValue != viewpointOffset {
//                transformItemViews()
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
    
    public var currentItemView: UIView?
//    {
//        return itemViews(at: currentItemIndex)
//    }
    public var indexesForVisibleItems: [Int]?
//    {
//        return itemViews.keys.sorted(by:#selector(self.compare(_:)))
//    }
    public private(set) var numberOfVisibleItems: Int = 0
    public var visibleItemViews: [UIView]?
//    {
//        return itemViews.values
//        //    return itemViews.objects(forKeys: indexesForVisibleItems, notFoundMarker: NSNull())
//    }
    public private(set) var itemWidth: CGFloat = 0.0
    public private(set) var contentView: UIView?
    public private(set) var toggle: CGFloat = 0.0
    public var autoscroll: CGFloat = 0.0 {
        didSet{
            if autoscroll != 0.0 {
//                startAnimation()
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
    private var itemViews: [Int : UIView] = [:]
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
//      func itemView(at index: Int) -> UIView? {
//      }
//
//      func indexOfItemView(_ view: UIView?) -> Int {
//      }
//
//      func indexOfItemViewOrSubview(_ view: UIView?) -> Int {
//      }
//
//      func offsetForItem(at index: Int) -> CGFloat {
//      }
//
//      func itemView(at point: CGPoint) -> UIView? {
//      }
    
    func removeItem(at index: Int, animated: Bool) {
    }
    
    func insertItem(at index: Int, animated: Bool) {
    }
    
    func reloadItem(at index: Int, animated: Bool) {
    }
    
    func reloadData() {
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


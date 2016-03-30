import UIKit

public final class HorizontalScrollingTextView : UIScrollView {
    
    class AlphaGradientView : UIView {
        
        private let gradiantMaskLayer:CAGradientLayer
        private let textView:HorizontalScrollingTextView
        
        private init(textView:HorizontalScrollingTextView) {
            gradiantMaskLayer = CAGradientLayer()
            self.textView = textView
            
            super.init(frame: textView.frame)
            addSubview(textView)
            textView.frame.origin = CGPoint.zero
            
            gradiantMaskLayer.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor, UIColor.blackColor().CGColor, UIColor.clearColor().CGColor]
            gradiantMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
            gradiantMaskLayer.endPoint = CGPoint(x: 1, y: 0.5)
            gradiantMaskLayer.locations = [0.0, 0.05, 0.95, 1.0]
            layer.mask = gradiantMaskLayer
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            gradiantMaskLayer.frame = bounds
            textView.frame = bounds
            textView.initialOffset = textView.frame.width * 0.025
        }
        
        override func intrinsicContentSize() -> CGSize {
            return textView.intrinsicContentSize()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private let mainLabel:UILabel
    private let endLabel:UILabel
    private var animationRemoved:Bool = true
    
    private var initialOffset:CGFloat = 0 {
        didSet {
            resetLabelSizes()
        }
    }
    
    private var minContentOffsetX:CGFloat {
        return 0
    }
    
    private var maxContentOffsetX:CGFloat {
        return contentSize.width - bounds.width
    }
    
    private var extendsPastBounds:Bool {
        return mainLabel.bounds.width > bounds.width
    }
    
    var estimatedHeight:CGFloat {
        return mainLabel.frame.height
    }
    
    public var scrollSpeedMultiplier:Double = 1.3
    
    public var text:String? {
        didSet {
//            UIView.transitionWithView(self, duration: 0.3, options: .TransitionFlipFromTop, animations: { 
                self.mainLabel.text = self.text
                self.endLabel.text = self.text
                self.resetLabelSizes()
//                }, completion: nil)

        }
    }
    
    public var viewWithAlphaGradients:UIView {
        return AlphaGradientView(textView: self)
    }
    
    
    var textGap:CGFloat = 65 {
        didSet {
            resetLabelSizes()
        }
    }
    
    //in seconds
    var delayBeforeRepeat:Double = 7
    
    public init(labelConfigurationBlock:(UILabel)->Void) {
        mainLabel = UILabel()
        endLabel = UILabel()
        
        super.init(frame: CGRect.zero)
        
        //using this to get an estimatated height at initialization
        let textForSizing = "text for sizing"
        mainLabel.text = textForSizing
        endLabel.text = textForSizing
        
        addSubview(mainLabel)
        addSubview(endLabel)
        
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        userInteractionEnabled = false
        bounces = false
        mainLabel.frame.origin = CGPoint.zero
        
        configureLabelsWithBlock(labelConfigurationBlock)
        
        mainLabel.text = nil
        endLabel.text = nil
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.stopScrolling),
                                                         name: UIApplicationDidEnterBackgroundNotification, object: UIApplication.sharedApplication())
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.startScrolling),
                                                         name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        stopScrolling()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override public func willMoveToSuperview(newSuperview: UIView?) {
        if newSuperview == nil {
            stopScrolling()
        }
        super.willMoveToSuperview(newSuperview)
    }
    
    override public func willMoveToWindow(newWindow: UIWindow?) {
        if newWindow == nil {
            stopScrolling()
        }
        super.willMoveToWindow(newWindow)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        resetLabelSizes()
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIScreen.mainScreen().bounds.width, height: estimatedHeight)
    }
    
    func startScrolling() {
        
        guard extendsPastBounds
            && text != nil
            && superview != nil
            && animationRemoved
            && UIApplication.sharedApplication().applicationState == .Active else {
                return
        }
        
        //want to move 1 pixel per frame at 60FPS
        let duration:Double = Double(maxContentOffsetX - contentOffset.x - initialOffset)/60.0 * scrollSpeedMultiplier
        
        let repeatAnimation = CAAnimationGroup()
        repeatAnimation.duration = duration + delayBeforeRepeat
        repeatAnimation.repeatCount = Float.infinity
        
        
        let scrollAnimation = CABasicAnimation(keyPath: "bounds")
        scrollAnimation.duration = duration
        scrollAnimation.fromValue = NSValue(CGRect:bounds)
        var newBounds = bounds
        newBounds.origin.x = maxContentOffsetX - initialOffset
        scrollAnimation.toValue = NSValue(CGRect: newBounds)
        
        repeatAnimation.animations = [scrollAnimation]
        
        self.layer.addAnimation(repeatAnimation, forKey: "scroll")
        animationRemoved = false
    }
    
    private func configureLabelsWithBlock(configurationBlock:((UILabel)->Void)?) {
        configurationBlock?(mainLabel)
        configurationBlock?(endLabel)
        
        mainLabel.numberOfLines = 1
        endLabel.lineBreakMode = .ByClipping
        endLabel.numberOfLines = 1
        
        resetLabelSizes()
    }
    
    func stopScrolling() {
        animationRemoved = true
        self.layer.removeAllAnimations()
    }
    
    private func resetLabelSizes() {
        stopScrolling()
        contentOffset.x = minContentOffsetX
        
        var width = mainLabel.frame.width == 0 ? UIScreen.mainScreen().bounds.width : mainLabel.frame.width
        let height = UIScreen.mainScreen().bounds.height
        repeat {
            width *= 2
            mainLabel.frame.size = mainLabel.textRectForBounds(CGRect(x:0, y:0, width: width, height: height), limitedToNumberOfLines: 1).size
        } while (mainLabel.frame.width == width)
        mainLabel.frame.size.width = max(mainLabel.frame.width, bounds.width)
        mainLabel.frame.origin.x = 0
        
        endLabel.frame.size = endLabel.textRectForBounds(bounds, limitedToNumberOfLines: 1).size
        endLabel.frame.origin.x = textGap + mainLabel.frame.width
        let totalWidth = mainLabel.frame.width + endLabel.frame.width + textGap
        self.contentSize = CGSize(width: totalWidth, height: mainLabel.bounds.height)
        
        let pastBounds = extendsPastBounds
        endLabel.hidden = !pastBounds
        
        if pastBounds && initialOffset != 0 {
            mainLabel.frame.origin.x = initialOffset
            endLabel.frame.origin.x += initialOffset
            contentSize.width += initialOffset
        }
        
        KyoozUtils.doInMainQueueAfterDelay(3) { [weak self] in
            self?.startScrolling()
        }
    }
    
}
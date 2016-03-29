import UIKit

public final class HorizontalScrollingTextView : UIScrollView {
    
    private let mainLabel:UILabel
    private let endLabel:UILabel
    private var animationRemoved:Bool = true
    
    private var minContentOffsetX:CGFloat {
        return 0
    }
    
    private var maxContentOffsetX:CGFloat {
        return contentSize.width - bounds.width
    }
    
    var estimatedHeight:CGFloat {
        return mainLabel.frame.height
    }
    
    var scrollIncrement:CGFloat = 2
    
    public var text:String? {
        didSet {
            mainLabel.text = text
            endLabel.text = text
            resetLabelSizes()
        }
    }
    
    var textGap:CGFloat = 65 {
        didSet {
            resetLabelSizes()
        }
    }
    
    //in seconds
    var delayBeforeRepeat:Double = 7
    
    override public var frame:CGRect {
        didSet {
            resetLabelSizes()
        }
    }
    
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
    
    func startScrolling() {
        
        guard mainLabel.bounds.width > bounds.width
            && text != nil
            && superview != nil
            && animationRemoved
            && UIApplication.sharedApplication().applicationState == .Active else {
                return
        }
        
        let duration:Double = Double(maxContentOffsetX - contentOffset.x)/60.0
        
        let repeatAnimation = CAAnimationGroup()
        repeatAnimation.duration = duration + delayBeforeRepeat
        repeatAnimation.repeatCount = Float.infinity
        
        
        let scrollAnimation = CABasicAnimation(keyPath: "bounds")
        scrollAnimation.duration = duration
        scrollAnimation.fromValue = NSValue(CGRect:bounds)
        var newBounds = bounds
        newBounds.origin.x = maxContentOffsetX
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
        
        endLabel.frame.size = endLabel.textRectForBounds(bounds, limitedToNumberOfLines: 1).size
        endLabel.frame.origin.x = textGap + mainLabel.frame.width
        let totalWidth = mainLabel.frame.width + endLabel.frame.width + textGap
        self.contentSize = CGSize(width: totalWidth, height: mainLabel.bounds.height)
        
        endLabel.hidden = mainLabel.bounds.width <= bounds.width
        KyoozUtils.doInMainQueueAfterDelay(3) { [weak self] in
            self?.startScrolling()
        }
    }
    
}
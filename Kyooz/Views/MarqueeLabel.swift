import UIKit

public class MarqueeLabel : UIView {
	
	private let subLabel = UILabel()
	private let replicatingLayer = CAReplicatorLayer()
	
	private let textGap:CGFloat = 65
    
    private let gradientMaskLayer:CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [UIColor.clearColor().CGColor, UIColor.blackColor().CGColor, UIColor.blackColor().CGColor, UIColor.clearColor().CGColor]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.locations = [0.0, 0.025, 0.975, 1.0]
        return layer
    }()
    
    private var animationRemoved = true
    private var extendsPastBounds:Bool {
        return subLabel.bounds.width > bounds.width
    }
    
    public var text:String? {
        didSet {
            subLabel.text = text
            resetLabelSizes()
        }
    }
	
	public func setText(text:String?, animated:Bool) {
		guard animated else {
			self.text = text
			return
		}
		subLabel.layer.shouldRasterize = false
		UIView.transitionWithView(self, duration: 0.5, options: .TransitionFlipFromBottom, animations: {
				self.text = text
			}, completion: {_ in
				self.subLabel.layer.shouldRasterize = true
		})
	}
	
	public init(labelConfigurationBlock:(UILabel)->()) {
		
		labelConfigurationBlock(subLabel)
		subLabel.numberOfLines = 1
		
		super.init(frame: CGRect.zero)
		
		userInteractionEnabled = false
		//using this to get an estimatated height at initialization
		subLabel.text = "text for sizing"
		resetLabelSizes()
		subLabel.text = nil
        
		layer.addSublayer(replicatingLayer)
		replicatingLayer.addSublayer(subLabel.layer)
        subLabel.layer.rasterizationScale = UIScreen.mainScreen().scale
        subLabel.layer.shouldRasterize = true
        
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
    
    public override func didMoveToWindow() {
        if window == nil {
            stopScrolling()
        } else {
            startScrolling()
        }
        super.didMoveToWindow()
    }
    
    public override func didMoveToSuperview() {
        if superview == nil {
            stopScrolling()
        } else {
            startScrolling()
        }
        super.didMoveToSuperview()
    }
    
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		resetLabelSizes()
		replicatingLayer.frame = bounds
        gradientMaskLayer.frame = bounds
	}
    
    public override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIScreen.mainScreen().bounds.width, height: subLabel.frame.height)
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
        let horizontalOffset = textGap + subLabel.bounds.width
        let duration:Double = Double(horizontalOffset)/60.0 * 1.5
        
        let repeatAnimation = CAAnimationGroup()
        repeatAnimation.duration = duration + 7
        repeatAnimation.repeatCount = Float.infinity
        
        
        let scrollAnimation = CABasicAnimation(keyPath: "position")
        scrollAnimation.duration = duration
        scrollAnimation.beginTime = 3.5
        scrollAnimation.toValue = NSValue(CGPoint: CGPoint(x: subLabel.layer.position.x - horizontalOffset, y: subLabel.layer.position.y))
        
        repeatAnimation.animations = [scrollAnimation]
        subLabel.layer.addAnimation(repeatAnimation, forKey: "scroll")
        animationRemoved = false
    }
	
	func stopScrolling() {
        animationRemoved = true
		subLabel.layer.removeAllAnimations()
	}
	
	private func resetLabelSizes() {
        func animateLabelPosition(newPosition:CGFloat) {
            guard newPosition != subLabel.frame.origin.x else { return }
            
            UIView.animateWithDuration(1.0, delay: 0.5, options: .CurveEaseInOut, animations: { [weak self] in
                self?.subLabel.frame.origin.x = newPosition
                }, completion: nil)
        }
        
		stopScrolling()
		
		let height = UIScreen.mainScreen().bounds.height
		subLabel.frame.size = subLabel.textRectForBounds(CGRect(x:0, y:0, width: CGFloat.infinity, height: height), limitedToNumberOfLines: 1).size
		subLabel.frame.size.width = max(subLabel.frame.width, bounds.width)
		
        if extendsPastBounds {
            replicatingLayer.instanceCount = 2
            replicatingLayer.instanceTransform = CATransform3DMakeTranslation(subLabel.frame.width + textGap, 0, 0)
            animateLabelPosition(frame.width * 0.025)
            layer.mask = gradientMaskLayer
        } else {
            animateLabelPosition(0)
            replicatingLayer.instanceCount = 1
            layer.mask = nil
        }
        
        startScrolling()
	}
	
}


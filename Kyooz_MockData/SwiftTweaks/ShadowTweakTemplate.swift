//
//  ShadowTweakTemplate.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 5/19/16.
//  Copyright © 2016 Khan Academy. All rights reserved.
//

import UIKit

/// A TweakTemplate for easy adjustment of CALayer shadows.
/// Creates tweaks for color, opacity, offsetY, offsetX, and radius.
public struct ShadowTweakTemplate: TweakGroupTemplateType {
	public let collectionName: String
	public let groupName: String

	public let color: Tweak<UIColor>
	public let opacity: Tweak<CGFloat>
	public let offsetY: Tweak<CGFloat>
	public let offsetX: Tweak<CGFloat>
	public let radius: Tweak<CGFloat>

	public var tweakCluster: [AnyTweak] {
		return [color, opacity, offsetY, radius].map(AnyTweak.init)
	}

	public init(
		_ collectionName: String,
		  _ groupName: String,
		    color: UIColor? = nil,
		    opacity: CGFloat? = nil,
		    offsetY: CGFloat? = nil,
		    offsetX: CGFloat? = nil,
		    radius: CGFloat? = nil
		) {
		self.collectionName = collectionName
		self.groupName = groupName

		self.color = Tweak(collectionName, groupName, "Color", color ?? ShadowTweakTemplate.colorDefault)

		self.opacity = Tweak(
			collectionName: collectionName,
			groupName: groupName,
			tweakName: "Opacity",
			defaultValue: ShadowTweakTemplate.opacityDefaults,
			minimumValue: opacity
		)

		self.offsetY = Tweak(
			collectionName: collectionName,
			groupName: groupName,
			tweakName: "Offset Y",
			defaultValue: ShadowTweakTemplate.offsetYDefaults,
			minimumValue: offsetY
		)

		self.offsetX = Tweak(
			collectionName: collectionName,
			groupName: groupName,
			tweakName: "Offset X",
			defaultValue: ShadowTweakTemplate.offsetXDefaults,
			minimumValue: offsetX
		)

		self.radius = Tweak(
			collectionName: collectionName,
			groupName: groupName,
			tweakName: "Radius",
			defaultValue: ShadowTweakTemplate.radiusDefaults,
			minimumValue: radius
		)
	}

	private static let colorDefault = UIColor.black

	private static let opacityDefaults = SignedNumberTweakDefaultParameters<CGFloat>(
		defaultValue: 0.2,
		minValue: 0.0,
		maxValue: 1.0,
		stepSize: 0.05
	)

	private static let offsetYDefaults = SignedNumberTweakDefaultParameters<CGFloat>(
		defaultValue: 0,
		minValue: nil,
		maxValue: nil,
		stepSize: 0.5
	)

	private static let offsetXDefaults = SignedNumberTweakDefaultParameters<CGFloat>(
		defaultValue: 0,
		minValue: nil,
		maxValue: nil,
		stepSize: 0.5
	)

	private static let radiusDefaults = SignedNumberTweakDefaultParameters<CGFloat>(
		defaultValue: 0,
		minValue: 0,
		maxValue: nil,
		stepSize: 0.5
	)
}

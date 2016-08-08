//
//  SpringAnimationTweakTemplate.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 4/8/16.
//  Copyright © 2016 Khan Academy. All rights reserved.
//

import UIKit



/// A shortcut to create a TweakGroup for an iOS-style spring animation.
/// Creates a collection of Tweak<T> with sensible defaults for a spring animation.
/// You can optionally provide a default value for each parameter, but the min / max / stepSize are automatically created with sensible defaults.
public struct SpringAnimationTweakTemplate: TweakGroupTemplateType {
	public let collectionName: String
	public let groupName: String
	
	public let stiffness: Tweak<CGFloat>
	public let mass: Tweak<CGFloat>
	public let damping: Tweak<CGFloat>
	public let initialSpringVelocity: Tweak<CGFloat>

	public var tweakCluster: [AnyTweak] {
		return [stiffness, mass, damping, initialSpringVelocity].map(AnyTweak.init)
	}

	public init(
		  _ collectionName: String,
		  _ groupName: String,
		    stiffness: CGFloat? = nil,
		    mass: CGFloat? = nil,
		    damping: CGFloat? = nil,
		    initialSpringVelocity: CGFloat? = nil
	) {
		self.collectionName = collectionName
		self.groupName = groupName

		self.stiffness = Tweak(
			collectionName: collectionName,
			groupName: groupName,
			tweakName: "Stiffness",
			defaultValue: SpringAnimationTweakTemplate.stiffnessDefaults,
			minimumValue: stiffness
		)

		self.mass = Tweak(
			collectionName: collectionName,
			groupName: groupName,
			tweakName: "Mass",
			defaultValue: SpringAnimationTweakTemplate.massDefaults,
			minimumValue: mass
		)

		self.damping = Tweak(
			collectionName: collectionName,
			groupName: groupName,
			tweakName: "Damping",
			defaultValue: SpringAnimationTweakTemplate.dampingDefaults,
			minimumValue: damping
		)

		self.initialSpringVelocity = Tweak(
			collectionName: collectionName,
			groupName: groupName,
			tweakName: "Initial V.",
			defaultValue: SpringAnimationTweakTemplate.initialSpringVelocityDefaults,
			minimumValue: initialSpringVelocity
		)
	}

	private static let stiffnessDefaults = SignedNumberTweakDefaultParameters<CGFloat>(
		defaultValue: 100,
		minValue: 1,
		maxValue: CGFloat.greatestFiniteMagnitude,
		stepSize: 100
	)
    
    private static let massDefaults = SignedNumberTweakDefaultParameters<CGFloat>(
        defaultValue: 1.0,
        minValue: 1,
        maxValue: CGFloat.greatestFiniteMagnitude,
        stepSize: 0.1
    )


	private static let dampingDefaults = SignedNumberTweakDefaultParameters<CGFloat>(
		defaultValue: 10,
		minValue: 0.0,
		maxValue: CGFloat.greatestFiniteMagnitude,
		stepSize: 1
	)

	private static let initialSpringVelocityDefaults = SignedNumberTweakDefaultParameters<CGFloat>(
		defaultValue: 0.0,
		minValue: -CGFloat.greatestFiniteMagnitude,
		maxValue: CGFloat.greatestFiniteMagnitude,
		stepSize: 5
	)
}

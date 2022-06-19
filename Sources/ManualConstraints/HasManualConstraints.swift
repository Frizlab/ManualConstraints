/*
Copyright 2022 François Lamboley

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. */

import Foundation



@MainActor
public protocol HasManualConstraints : AnyObject {
	
	/** Defensive programming: If a manual constraint is added to a view for a key that it does noto support, we crash (in debug mode). */
	static func supportsManualConstraintKey<Key : ManualConstraintKey>(_ key: Key.Type) -> Bool
	
	/** Should only be modified using ``ManualConstraint.addManualConstraints(on:for:)``. */
	var manualConstraints: ManualConstraintStorage {get set}
	func constrainedValue<Key : ManualConstraintKey>(for key: Key.Type) -> Key.Value?
	
	func refreshManualConstraint<Key : ManualConstraintKey>(_ key: Key.Type, from source: HasManualConstraints?)
	
}

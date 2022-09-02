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
import os.log



@MainActor
public struct ManualConstraint<Key : ManualConstraintKey> {
	
	public static func addManualConstraints(on objects: HasManualConstraints..., for key: Key.Type = Key.self) {
		addManualConstraints(on: objects, for: key)
	}
	
	public static func addManualConstraints(on objects: [HasManualConstraints], for key: Key.Type = Key.self) {
		var additionalObjects = [HasManualConstraints]()
		let storage = objects.reduce(nil as BoundObjectsStorage?, { currentStorage, currentObject in
			/* Defensive programming: We check the object support the manual constraint key.
			 * If not, in production the constraint will still be added (it won’t hurt, it will just not be used,
			 *  or might be if the object simply forgot to declare the constraint key as being supported).
			 * In non-production builds though, we’ll crash with an assertion failure. */
			if !type(of: currentObject).supportsManualConstraintKey(key) {
				assertionFailure("Tried to add manual constraint for key \(key) on object \(currentObject) that do not explicitly support it.")
				Logger.main.error("Tried to add manual constraint for key \(key)) on object \(String(describing: currentObject)) that do not explicitly support it.")
			}
			
			if let currentStorage = currentStorage {
				if let currentObjectStorage = currentObject.manualConstraints.get(key)?.storage, currentObjectStorage !== currentStorage {
					Logger.main.debug("Merging two bound objects storages! This means two previously unrelated manual contraint groups are now becoming a single group.")
					additionalObjects += currentObjectStorage.boundObjects
					additionalObjects += currentStorage.boundObjects
				}
				return currentStorage
			} else {
				return currentObject.manualConstraints.get(key)?.storage
			}
		}) ?? BoundObjectsStorage()
		(objects + additionalObjects).forEach{
			$0.manualConstraints[key] = ManualConstraint<Key>(storage: storage)
			storage._boundObjects.add($0)
		}
		for v in storage.boundObjects {
			v.refreshManualConstraint(key, from: nil)
		}
	}
	
	public var boundObjects: [HasManualConstraints] {
		return storage?.boundObjects ?? []
	}
	
	internal init() {
	}
	
	private init(storage: BoundObjectsStorage) {
		self.storage = storage
	}
	
	@discardableResult
	public func removeFromBoundObjects(_ removedObjects: HasManualConstraints...) -> Bool {
		return removeFromBoundObjects(removedObjects)
	}
	
	/** Returns `true` if the object was in the bound objects. */
	@discardableResult
	public func removeFromBoundObjects(_ removedObjects: [HasManualConstraints]) -> Bool {
		for removedObject in removedObjects {
			guard storage?._boundObjects.contains(removedObject) ?? false else {
				Logger.main.debug("Asked to remove bound object \(String(describing: removedObject)) from a constraint from which this object is not bound.")
				/* The assert below is invalid (the constraint might exist in another group). */
//				assert(removedObject.manualConstraints[Key.self] == nil)
				return false
			}
			assert(removedObject.manualConstraints.get(Key.self)?.storage === storage)
			removedObject.manualConstraints.set(Key.self, to: nil)
			storage?._boundObjects.remove(removedObject)
			
			removedObject.refreshManualConstraint(Key.self, from: nil)
		}
		
		notifyBoundObjects()
		return true
	}
	
	public func boundObjects(except excludedObject: HasManualConstraints? = nil) -> [HasManualConstraints] {
		/* Would work without this guard, but we get a useless debug message. */
		guard storage != nil else {
			return []
		}
		
		let boundObjects = boundObjects
		let filtered = boundObjects.filter{ $0 !== excludedObject }
		
		if let excludedObject = excludedObject, boundObjects.count == filtered.count {
			Logger.main.debug("Asked for bound objects except \(String(describing: excludedObject)), which is not a part of the bound objects anyway…")
		}
		
		return filtered
	}
	
	public func notifyBoundObjects(except excludedObject: HasManualConstraints? = nil, source: HasManualConstraints? = nil) {
		for v in boundObjects(except: excludedObject) {
			v.refreshManualConstraint(Key.self, from: source)
		}
	}
	
	public func constrainedValues(exceptFrom excludedObject: HasManualConstraints? = nil) -> [Key.Value] {
		return boundObjects(except: excludedObject).compactMap{ $0.constrainedValue(for: Key.self) }
	}
	
	private var storage: BoundObjectsStorage? {
		willSet {
			if storage != nil, newValue != nil, storage !== newValue {
				Logger.main.error("Setting new storage on a manual constraint where both new and old storage are non-nil, but new value is different than old value. This is an internal logic error.")
			}
		}
	}
	
	@MainActor
	private final class BoundObjectsStorage/* : CustomDebugStringConvertible*/ {
		
		/* While https://github.com/apple/swift/issues/42677 is not resolved, we cannot have an NSHashTable<HasManualConstraints> though this variable technically is that.
		 * Instead we used a workaround in the mean time. */
		var _boundObjects = NSHashTable<AnyObject>.init(options: .weakMemory, capacity: 3)
		var boundObjects: [HasManualConstraints] {
			return _boundObjects.allObjects as! [HasManualConstraints]
		}
		
//		nonisolated var debugDescription: String {
//			let all = _boundObjects.allObjects
//			return "BoundObjectsStorage - \(all.count) objects: \(all)"
//		}
		
	}
	
}

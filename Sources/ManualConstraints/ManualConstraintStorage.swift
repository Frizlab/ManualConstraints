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



/** From Vapor’s Storage. */
@MainActor
public struct ManualConstraintStorage {
	
	public nonisolated init() {
	}
	
	public mutating func clear() {
		storage = [:]
	}
	
	public subscript<Key>(_ key: Key.Type) -> ManualConstraint<Key> where Key : ManualConstraintKey {
		get {get(Key.self) ?? ManualConstraint()}
		set {set(Key.self, to: newValue)}
	}
	
	public func contains<Key>(_ key: Key.Type) -> Bool {
		storage.keys.contains(ObjectIdentifier(Key.self))
	}
	
	public func get<Key>(_ key: Key.Type) -> ManualConstraint<Key>? where Key: ManualConstraintKey {
		guard let value = self.storage[ObjectIdentifier(Key.self)] as! Value<Key>? else {
			return nil
		}
		return value.value
	}
	
	public mutating func set<Key>(_ key: Key.Type, to value: ManualConstraint<Key>?) where Key: ManualConstraintKey {
		let key = ObjectIdentifier(Key.self)
		storage[key] = value.flatMap(Value.init(value:))
	}
	
	/* ***************
	   MARK: - Private
	   *************** */
	
	private var storage = [ObjectIdentifier: AnyStorageValue]()
	
	struct Value<T : ManualConstraintKey> : AnyStorageValue {
		
		var value: ManualConstraint<T>
		
	}
	
}


fileprivate protocol AnyStorageValue {
}

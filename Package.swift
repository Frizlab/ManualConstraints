// swift-tools-version:5.5
import PackageDescription


let package = Package(
	name: "ManualConstraints",
	platforms: [.macOS(.v11), .iOS(.v14), .tvOS(.v14), .watchOS(.v7)], /* For the Logger… */
	products: [.library(name: "ManualConstraints", targets: ["ManualConstraints"])],
	targets: [
		.target(name: "ManualConstraints")
	]
)

/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2018 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/// Targets are the basic building blocks of a package.
/// 
/// Each target contains a set of source files that are compiled into a module or
/// test suite. Targets can be vended to other packages by defining products that
/// include them.
/// 
/// Targets may depend on targets within the same package and on products vended
/// by its package dependencies.
public final class Target {

    /// The type of this target.
    public enum TargetType: String, Encodable {
        case regular
        case test
        case system
    }

    /// Represents a target's dependency on another entity.
    public enum Dependency {
      #if PACKAGE_DESCRIPTION_4
        case targetItem(name: String)
        case productItem(name: String, package: String?)
        case byNameItem(name: String)
      #else
        case _targetItem(name: String)
        case _productItem(name: String, package: String?)
        case _byNameItem(name: String)
      #endif
    }

    /// The name of the target.
    public var name: String

    /// The path of the target, relative to the package root.
    ///
    /// If nil, a directory with the target's name will be searched in the
    /// predefined search paths. The predefined search paths are the following
    /// directories under the package root:
    ///   - for regular targets: Sources, Source, src, srcs
    ///   - for test targets: Tests, Sources, Source, src, srcs
    public var path: String?

    /// The source files in this target.
    ///
    /// If nil, all valid source files found in the target's path will be included.
    ///
    /// This can contain directories and individual source files. Directories
    /// will be searched recursively for valid source files.
    ///
    /// Paths specified are relative to the target path.
    public var sources: [String]?

    /// List of paths to be excluded from source inference.
    ///
    /// Exclude paths are relative to the target path.
    /// This property has more precedence than sources property.
    public var exclude: [String]

    /// If this is a test target.
    public var isTest: Bool {
        return type == .test
    }

    /// Dependencies on other entities inside or outside the package.
    public var dependencies: [Dependency]

    /// The path to the directory containing public headers of a C language target.
    ///
    /// If a value is not provided, the directory will be set to "include".
    public var publicHeadersPath: String?

    /// The type of target.
    public let type: TargetType

    /// `pkgconfig` name to use for system library target. If present, swiftpm will try to
    /// search for <name>.pc file to get the additional flags needed for the
    /// system target.
    public let pkgConfig: String?

    /// Providers array for the System library target.
    public let providers: [SystemPackageProvider]?

    /// C build settings.
    @available(_PackageDescription, introduced: 5)
    public var cSettings: [CSetting]? {
        get { return _cSettings }
        set { _cSettings = newValue }
    }
    private var _cSettings: [CSetting]?

    /// C++ build settings.
    @available(_PackageDescription, introduced: 5)
    public var cxxSettings: [CXXSetting]? {
        get { return _cxxSettings }
        set { _cxxSettings = newValue }
    }
    private var _cxxSettings: [CXXSetting]?

    /// Swift build settings.
    @available(_PackageDescription, introduced: 5)
    public var swiftSettings: [SwiftSetting]? {
        get { return _swiftSettings }
        set { _swiftSettings = newValue }
    }
    private var _swiftSettings: [SwiftSetting]?

    /// Linker build settings.
    @available(_PackageDescription, introduced: 5)
    public var linkerSettings: [LinkerSetting]? {
        get { return _linkerSettings }
        set { _linkerSettings = newValue }
    }
    private var _linkerSettings: [LinkerSetting]?

    /// Construct a target.
    private init(
        name: String,
        dependencies: [Dependency],
        path: String?,
        exclude: [String],
        sources: [String]?,
        publicHeadersPath: String?,
        type: TargetType,
        pkgConfig: String? = nil,
        providers: [SystemPackageProvider]? = nil,
        cSettings: [CSetting]? = nil,
        cxxSettings: [CXXSetting]? = nil,
        swiftSettings: [SwiftSetting]? = nil,
        linkerSettings: [LinkerSetting]? = nil
    ) {
        self.name = name
        self.dependencies = dependencies
        self.path = path
        self.publicHeadersPath = publicHeadersPath
        self.sources = sources
        self.exclude = exclude
        self.type = type
        self.pkgConfig = pkgConfig
        self.providers = providers
        self._cSettings = cSettings
        self._cxxSettings = cxxSettings
        self._swiftSettings = swiftSettings
        self._linkerSettings = linkerSettings

        switch type {
        case .regular, .test:
            precondition(pkgConfig == nil && providers == nil)
        case .system: break
        }
    }

    /// Create a library or executable target.
    ///
    /// A target can either contain Swift or C-family source files. You cannot
    /// mix Swift and C-family source files within a target. A target is
    /// considered to be an executable target if there is a `main.swift`,
    /// `main.m`, `main.c` or `main.cpp` file in the target's directory. All
    /// other targets are considered to be library targets.
    ///
    /// - Parameters:
    ///   - name: The name of the target.
    ///   - dependencies: The dependencies of the target. These can either be other targets in the package or products from package dependencies.
    ///   - path: The custom path for the target. By default, targets will be looked up in the <package-root>/Sources/<target-name> directory.
    ///       Do not escape the package root, i.e. values like "../Foo" or "/Foo" are invalid.
    ///   - exclude: A list of paths to exclude from being considered source files. This path is relative to the target's directory.
    ///   - sources: An explicit list of source files.
    ///   - publicHeadersPath: The directory containing public headers of a C-family family library target.
    @available(_PackageDescription, introduced: 4, obsoleted: 5)
    public static func target(
        name: String,
        dependencies: [Dependency] = [],
        path: String? = nil,
        exclude: [String] = [],
        sources: [String]? = nil,
        publicHeadersPath: String? = nil
    ) -> Target {
        return Target(
            name: name,
            dependencies: dependencies,
            path: path,
            exclude: exclude,
            sources: sources,
            publicHeadersPath: publicHeadersPath,
            type: .regular
        )
    }

    /// Create a library or executable target.
    ///
    /// A target can either contain Swift or C-family source files. You cannot
    /// mix Swift and C-family source files within a target. A target is
    /// considered to be an executable target if there is a `main.swift`,
    /// `main.m`, `main.c` or `main.cpp` file in the target's directory. All
    /// other targets are considered to be library targets.
    ///
    /// - Parameters:
    ///   - name: The name of the target.
    ///   - dependencies: The dependencies of the target. These can either be other targets in the package or products from package dependencies.
    ///   - path: The custom path for the target. By default, targets will be looked up in the <package-root>/Sources/<target-name> directory.
    ///       Do not escape the package root, i.e. values like "../Foo" or "/Foo" are invalid.
    ///   - exclude: A list of paths to exclude from being considered source files. This path is relative to the target's directory.
    ///   - sources: An explicit list of source files.
    ///   - publicHeadersPath: The directory containing public headers of a C-family family library target.
    ///   - cSettings: The C settings for this target.
    ///   - cxxSettings: The C++ settings for this target.
    ///   - swiftSettings: The Swift settings for this target.
    ///   - linkerSettings: The linker settings for this target.
    @available(_PackageDescription, introduced: 5)
    public static func target(
        name: String,
        dependencies: [Dependency] = [],
        path: String? = nil,
        exclude: [String] = [],
        sources: [String]? = nil,
        publicHeadersPath: String? = nil,
        cSettings: [CSetting]? = nil,
        cxxSettings: [CXXSetting]? = nil,
        swiftSettings: [SwiftSetting]? = nil,
        linkerSettings: [LinkerSetting]? = nil
    ) -> Target {
        return Target(
            name: name,
            dependencies: dependencies,
            path: path,
            exclude: exclude,
            sources: sources,
            publicHeadersPath: publicHeadersPath,
            type: .regular,
            cSettings: cSettings,
            cxxSettings: cxxSettings,
            swiftSettings: swiftSettings,
            linkerSettings: linkerSettings
        )
    }

    /// Create a test target.
    ///
    /// Test targets are written using the XCTest testing framework. Test targets
    /// generally declare target dependency on the targets they test.
    ///
    /// - Parameters:
    ///   - name: The name of the target.
    ///   - dependencies: The dependencies of the target. These can either be other targets in the package or products from other packages.
    ///   - path: The custom path for the target. By default, targets will be looked up in the <package-root>/Sources/<target-name> directory.
    ///       Do not escape the package root, i.e. values like "../Foo" or "/Foo" are invalid.
    ///   - exclude: A list of paths to exclude from being considered source files. This path is relative to the target's directory.
    ///   - sources: An explicit list of source files.
    @available(_PackageDescription, introduced: 4, obsoleted: 5)
    public static func testTarget(
        name: String,
        dependencies: [Dependency] = [],
        path: String? = nil,
        exclude: [String] = [],
        sources: [String]? = nil
    ) -> Target {
        return Target(
            name: name,
            dependencies: dependencies,
            path: path,
            exclude: exclude,
            sources: sources,
            publicHeadersPath: nil,
            type: .test
        )
    }

    /// Create a test target.
    ///
    /// Test targets are written using the XCTest testing framework. Test targets
    /// generally declare target dependency on the targets they test.
    ///
    /// - Parameters:
    ///   - name: The name of the target.
    ///   - dependencies: The dependencies of the target. These can either be other targets in the package or products from other packages.
    ///   - path: The custom path for the target. By default, targets will be looked up in the <package-root>/Sources/<target-name> directory.
    ///       Do not escape the package root, i.e. values like "../Foo" or "/Foo" are invalid.
    ///   - exclude: A list of paths to exclude from being considered source files. This path is relative to the target's directory.
    ///   - sources: An explicit list of source files.
    ///   - cSettings: The C settings for this target.
    ///   - cxxSettings: The C++ settings for this target.
    ///   - swiftSettings: The Swift settings for this target.
    ///   - linkerSettings: The linker settings for this target.
    @available(_PackageDescription, introduced: 5)
    public static func testTarget(
        name: String,
        dependencies: [Dependency] = [],
        path: String? = nil,
        exclude: [String] = [],
        sources: [String]? = nil,
        cSettings: [CSetting]? = nil,
        cxxSettings: [CXXSetting]? = nil,
        swiftSettings: [SwiftSetting]? = nil,
        linkerSettings: [LinkerSetting]? = nil
    ) -> Target {
        return Target(
            name: name,
            dependencies: dependencies,
            path: path,
            exclude: exclude,
            sources: sources,
            publicHeadersPath: nil,
            type: .test,
            cSettings: cSettings,
            cxxSettings: cxxSettings,
            swiftSettings: swiftSettings,
            linkerSettings: linkerSettings
        )
    }


  #if !PACKAGE_DESCRIPTION_4
    /// Create a system library target.
    ///
    /// System library targets are used to adapt a library installed on the system to
    /// work with Swift packages. Such libraries are generally installed by system
    /// package managers (such as Homebrew and APT) and exposed to Swift packages by
    /// providing a modulemap file along with other metadata such as the library's 
    /// pkg-config name.
    ///
    /// - Parameters:
    ///   - name: The name of the target.
    ///   - path: The custom path for the target. By default, targets will be looked up in the <package-root>/Sources/<target-name> directory.
    ///       Do not escape the package root, i.e. values like "../Foo" or "/Foo" are invalid.
    ///   - pkgConfig: The name of the pkg-config file for this system library.
    ///   - providers: The providers for this system library.
    public static func systemLibrary(
        name: String,
        path: String? = nil,
        pkgConfig: String? = nil,
        providers: [SystemPackageProvider]? = nil
    ) -> Target {
        return Target(
            name: name,
            dependencies: [],
            path: path,
            exclude: [],
            sources: nil,
            publicHeadersPath: nil,
            type: .system,
            pkgConfig: pkgConfig,
            providers: providers)
    }
  #endif
}

extension Target: Encodable {
    private enum CodingKeys: CodingKey {
        case name
        case path
        case sources
        case exclude
        case dependencies
        case publicHeadersPath
        case type
        case pkgConfig
        case providers
        case cSettings
        case cxxSettings
        case swiftSettings
        case linkerSettings
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encode(path, forKey: .path)
        try container.encode(sources, forKey: .sources)
        try container.encode(exclude, forKey: .exclude)
        try container.encode(dependencies, forKey: .dependencies)
        try container.encode(publicHeadersPath, forKey: .publicHeadersPath)
        try container.encode(type, forKey: .type)
        try container.encode(pkgConfig, forKey: .pkgConfig)
        try container.encode(providers, forKey: .providers)

        if let cSettings = self._cSettings {
            try container.encode(cSettings, forKey: .cSettings)
        }

        if let cxxSettings = self._cxxSettings {
            try container.encode(cxxSettings, forKey: .cxxSettings)
        }

        if let swiftSettings = self._swiftSettings {
            try container.encode(swiftSettings, forKey: .swiftSettings)
        }

        if let linkerSettings = self._linkerSettings {
            try container.encode(linkerSettings, forKey: .linkerSettings)
        }
    }
}

extension Target.Dependency {
    /// A dependency on a target in the same package.
    public static func target(name: String) -> Target.Dependency {
      #if PACKAGE_DESCRIPTION_4
        return .targetItem(name: name)
      #else
        return ._targetItem(name: name)
      #endif
    }

    /// A dependency on a product from a package dependency.
    public static func product(name: String, package: String? = nil) -> Target.Dependency {
      #if PACKAGE_DESCRIPTION_4
        return .productItem(name: name, package: package)
      #else
        return ._productItem(name: name, package: package)
      #endif
    }

    // A by-name dependency that resolves to either a target or a product,
    // as above, after the package graph has been loaded.
    public static func byName(name: String) -> Target.Dependency {
      #if PACKAGE_DESCRIPTION_4
        return .byNameItem(name: name)
      #else
        return ._byNameItem(name: name)
      #endif
    }
}

// MARK: ExpressibleByStringLiteral

extension Target.Dependency: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
      #if PACKAGE_DESCRIPTION_4
        self = .byNameItem(name: value)
      #else
        self = ._byNameItem(name: value)
      #endif
    }
}

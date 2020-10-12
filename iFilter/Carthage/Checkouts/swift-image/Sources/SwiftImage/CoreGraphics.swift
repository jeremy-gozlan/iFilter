#if canImport(CoreGraphics)
import CoreGraphics
import Foundation

public enum CGContextCoordinates {
    case original
    case natural
}

public protocol _CGChannel {
    associatedtype _EZ_DirectChannel: _CGDirectChannel, Numeric

    init(_ez_directChannel: _EZ_DirectChannel)
    var _ez_directChannel: _EZ_DirectChannel { get }

    static func _ez_rgba(from: PremultipliedRGBA<_EZ_DirectChannel>) -> RGBA<Self>
    static func _ez_premultipliedRGBA(from: RGBA<Self>) -> PremultipliedRGBA<_EZ_DirectChannel>
}

public protocol _CGDirectChannel: _CGChannel where _EZ_DirectChannel == Self {
    static var _ez_cgChannelDefault: Self { get }
}

extension _CGDirectChannel {
    public init(_ez_directChannel directChannel: _EZ_DirectChannel) {
        self = directChannel
    }

    public var _ez_directChannel: _EZ_DirectChannel {
        return self
    }
}

extension UInt8: _CGDirectChannel {
    public typealias _EZ_DirectChannel = UInt8

    public static func _ez_rgba(from premultipliedRGBA: PremultipliedRGBA<UInt8>) -> RGBA<UInt8> {
        return RGBA<UInt8>(premultipliedRGBA)
    }

    public static func _ez_premultipliedRGBA(from rgba: RGBA<UInt8>) -> PremultipliedRGBA<UInt8> {
        return PremultipliedRGBA<UInt8>(rgba)
    }

    public static var _ez_cgChannelDefault: UInt8 { return 0 }
}

extension UInt16: _CGDirectChannel {
    public typealias _EZ_DirectChannel = UInt16

    public static func _ez_rgba(from premultipliedRGBA: PremultipliedRGBA<UInt16>) -> RGBA<UInt16> {
        return RGBA<UInt16>(premultipliedRGBA)
    }

    public static func _ez_premultipliedRGBA(from rgba: RGBA<UInt16>) -> PremultipliedRGBA<UInt16> {
        return PremultipliedRGBA<UInt16>(rgba)
    }

    public static var _ez_cgChannelDefault: UInt16 { return 0 }
}

extension Float: _CGChannel {
    public typealias _EZ_DirectChannel = UInt8

    public init(_ez_directChannel directChannel: UInt8) {
        self = Float(directChannel) / 255
    }

    public var _ez_directChannel: UInt8 {
        return UInt8(clamp(self * 255, lower: 0, upper: 255))
    }

    public static func _ez_rgba(from premultipliedRGBA: PremultipliedRGBA<UInt8>) -> RGBA<Float> {
        return RGBA<Float>(premultipliedRGBA.map(Float.init(_ez_directChannel:)))
    }

    public static func _ez_premultipliedRGBA(from rgba: RGBA<Float>) -> PremultipliedRGBA<UInt8> {
        return PremultipliedRGBA<UInt8>(rgba.map { $0._ez_directChannel })
    }
}

extension Double: _CGChannel {
    public typealias _EZ_DirectChannel = UInt8

    public init(_ez_directChannel directChannel: UInt8) {
        self = Double(directChannel) / 255
    }

    public var _ez_directChannel: UInt8 {
        return UInt8(clamp(self * 255, lower: 0, upper: 255))
    }

    public static func _ez_rgba(from premultipliedRGBA: PremultipliedRGBA<UInt8>) -> RGBA<Double> {
        return RGBA<Double>(premultipliedRGBA.map(Double.init(_ez_directChannel:)))
    }

    public static func _ez_premultipliedRGBA(from rgba: RGBA<Double>) -> PremultipliedRGBA<UInt8> {
        return PremultipliedRGBA<UInt8>(rgba.map { $0._ez_directChannel })
    }
}

extension Bool: _CGChannel {
    public typealias _EZ_DirectChannel = UInt8

    public init(_ez_directChannel directChannel: UInt8) {
        self = directChannel >= 128
    }

    public var _ez_directChannel: _EZ_DirectChannel {
        return self ? 255 : 0
    }

    public static func _ez_rgba(from premultipliedRGBA: PremultipliedRGBA<UInt8>) -> RGBA<Bool> {
        return RGBA<UInt8>(premultipliedRGBA).map(Bool.init(_ez_directChannel:))
    }

    public static func _ez_premultipliedRGBA(from rgba: RGBA<Bool>) -> PremultipliedRGBA<UInt8> {
        return PremultipliedRGBA<UInt8>(rgba.map { $0._ez_directChannel })
    }
}

public protocol _CGPixel {
    associatedtype _EZ_DirectPixel: _CGDirectPixel
    associatedtype _EZ_PixelDirectChannel: _CGDirectChannel

    init(_ez_directPixel: _EZ_DirectPixel)

    var _ez_directPixel: _EZ_DirectPixel { get }

    static var _ez_cgColorSpace: CGColorSpace { get }
    static var _ez_cgBitmapInfo: CGBitmapInfo { get }
}

public protocol _CGDirectPixel: _CGPixel where _EZ_DirectPixel == Self {
    static var _ez_cgPixelDefault: Self { get }
}

extension _CGDirectPixel {
    public var _ez_directPixel: _EZ_DirectPixel {
        return self
    }

    public init(_ez_directPixel directPixel: _EZ_DirectPixel) {
        self = directPixel
    }
}

extension UInt8: _CGDirectPixel {
    public typealias _EZ_DirectPixel = UInt8
    public typealias _EZ_PixelDirectChannel = UInt8
    
    public static var _ez_cgColorSpace: CGColorSpace {
        return CGColorSpaceCreateDeviceGray()
    }
    
    public static var _ez_cgBitmapInfo: CGBitmapInfo {
        return CGBitmapInfo()
    }
    
    public static var _ez_cgPixelDefault: UInt8 {
        return 0
    }
}

extension UInt16: _CGDirectPixel {
    public typealias _EZ_DirectPixel = UInt16
    public typealias _EZ_PixelDirectChannel = UInt16
    
    public static var _ez_cgColorSpace: CGColorSpace {
        return CGColorSpaceCreateDeviceGray()
    }
    
    public static var _ez_cgBitmapInfo: CGBitmapInfo {
        return CGBitmapInfo()
    }

    public static var _ez_cgPixelDefault: UInt16 {
        return 0
    }
}

extension Float: _CGPixel {
    public typealias _EZ_DirectPixel = UInt8
    public typealias _EZ_PixelDirectChannel = UInt8

    public var _ez_directPixel: UInt8 {
        return UInt8(clamp(self * 255, lower: 0, upper: 255))
    }
    
    public static var _ez_cgColorSpace: CGColorSpace {
        return CGColorSpaceCreateDeviceGray()
    }
    
    public static var _ez_cgBitmapInfo: CGBitmapInfo {
        return CGBitmapInfo()
    }

    public init(_ez_directPixel directPixel: UInt8) {
        self = Float(directPixel) / 255
    }
}

extension Double: _CGPixel {
    public typealias _EZ_DirectPixel = UInt8
    public typealias _EZ_PixelDirectChannel = UInt8

    public var _ez_directPixel: UInt8 {
        return UInt8(clamp(self * 255, lower: 0, upper: 255))
    }
    
    public static var _ez_cgColorSpace: CGColorSpace {
        return CGColorSpaceCreateDeviceGray()
    }
    
    public static var _ez_cgBitmapInfo: CGBitmapInfo {
        return CGBitmapInfo()
    }

    public init(_ez_directPixel directPixel: UInt8) {
        self = Double(directPixel) / 255
    }
}

extension Bool: _CGPixel {
    public typealias _EZ_DirectPixel = UInt8
    public typealias _EZ_PixelDirectChannel = UInt8

    public var _ez_directPixel: UInt8 {
        return self ? 255 : 0
    }
    
    public static var _ez_cgColorSpace: CGColorSpace {
        return CGColorSpaceCreateDeviceGray()
    }
    
    public static var _ez_cgBitmapInfo: CGBitmapInfo {
        return CGBitmapInfo()
    }

    public init(_ez_directPixel directPixel: UInt8) {
        self = directPixel >= 128
    }
}

extension RGB: _CGPixel where Channel: _CGChannel {
    public typealias _EZ_DirectPixel = RGB<Channel._EZ_DirectChannel>
    public typealias _EZ_PixelDirectChannel = Channel._EZ_DirectChannel

    public init(_ez_directPixel directPixel: RGB<Channel._EZ_DirectChannel>) {
        self = directPixel.map(Channel.init(_ez_directChannel:))
    }
    
    public var _ez_directPixel: RGB<Channel._EZ_DirectChannel> {
        return map { $0._ez_directChannel }
    }
    
    public static var _ez_cgColorSpace: CGColorSpace {
        return CGColorSpaceCreateDeviceRGB()
    }
    
    public static var _ez_cgBitmapInfo: CGBitmapInfo {
        return CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
    }
}

extension RGB: _CGDirectPixel where Channel: _CGDirectChannel {
    public static var _ez_cgPixelDefault: RGB<Channel> {
        return RGB<Channel>(
            red: Channel._ez_cgChannelDefault,
            green: Channel._ez_cgChannelDefault,
            blue: Channel._ez_cgChannelDefault
        )
    }
}

extension RGBA: _CGPixel where Channel: _CGChannel {
    public typealias _EZ_DirectPixel = PremultipliedRGBA<Channel._EZ_DirectChannel>
    public typealias _EZ_PixelDirectChannel = Channel._EZ_DirectChannel

    public init(_ez_directPixel directPixel: PremultipliedRGBA<Channel._EZ_DirectChannel>) {
        self = Channel._ez_rgba(from: directPixel)
    }

    public var _ez_directPixel: PremultipliedRGBA<Channel._EZ_DirectChannel> {
        return Channel._ez_premultipliedRGBA(from: self)
    }
    
    public static var _ez_cgColorSpace: CGColorSpace {
        return CGColorSpaceCreateDeviceRGB()
    }
    
    public static var _ez_cgBitmapInfo: CGBitmapInfo {
        return CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    }
}

extension PremultipliedRGBA: _CGPixel where Channel: _CGChannel {
    public typealias _EZ_DirectPixel = PremultipliedRGBA<Channel._EZ_DirectChannel>
    public typealias _EZ_PixelDirectChannel = Channel._EZ_DirectChannel

    public init(_ez_directPixel directPixel: PremultipliedRGBA<Channel._EZ_DirectChannel>) {
        self = directPixel.map(Channel.init(_ez_directChannel:))
    }

    public var _ez_directPixel: PremultipliedRGBA<Channel._EZ_DirectChannel> {
        return map { $0._ez_directChannel }
    }
    
    public static var _ez_cgColorSpace: CGColorSpace {
        return CGColorSpaceCreateDeviceRGB()
    }
    
    public static var _ez_cgBitmapInfo: CGBitmapInfo {
        return CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    }
}

extension PremultipliedRGBA: _CGDirectPixel where Channel: _CGDirectChannel {
    public static var _ez_cgPixelDefault: PremultipliedRGBA<Channel> {
        return PremultipliedRGBA<Channel>(
            red: Channel._ez_cgChannelDefault,
            green: Channel._ez_cgChannelDefault,
            blue: Channel._ez_cgChannelDefault,
            alpha: Channel._ez_cgChannelDefault
        )
    }
}

public protocol _CGImageConvertible {
    init(cgImage: CGImage)
    var cgImage: CGImage { get }
}

public protocol _CGImageDirectlyConvertible: _CGImageConvertible {
    func withCGImage<R>(_ body: (CGImage) throws -> R) rethrows -> R
    mutating func withCGContext(coordinates: CGContextCoordinates, _ body: (CGContext) throws -> Void) rethrows
}

extension Image: _CGImageConvertible where Pixel: _CGPixel {
    @inlinable
    public init(cgImage: CGImage) {
        let width = cgImage.width
        let height = cgImage.height

        let pixels = [Pixel._EZ_DirectPixel](repeating: Pixel._EZ_DirectPixel._ez_cgPixelDefault, count: width * height)
        var image = Image<Pixel._EZ_DirectPixel>(width: width, height: height, pixels: pixels)
        image.withCGContext(coordinates: .original) { context in
            let rect = CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height))
            context.draw(cgImage, in: rect)
        }

        self = image.map(Pixel.init(_ez_directPixel:))
    }

    @inlinable
    public var cgImage: CGImage {
        return map { $0._ez_directPixel }.cgImage
    }
}

extension Image: _CGImageDirectlyConvertible where Pixel: _CGDirectPixel {
    @inlinable
    public var cgImage: CGImage {
        let length = count * MemoryLayout<Pixel>.size

        let provider: CGDataProvider = CGDataProvider(data: Data(
            bytes: UnsafeMutableRawPointer(mutating: pixels),
            count: length
        ) as CFData)!

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: MemoryLayout<Pixel._EZ_PixelDirectChannel>.size * 8,
            bitsPerPixel: MemoryLayout<Pixel>.size * 8,
            bytesPerRow: MemoryLayout<Pixel>.size * width,
            space: Pixel._ez_cgColorSpace,
            bitmapInfo: Pixel._ez_cgBitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent
        )!

    }

    @inlinable
    public func withCGImage<R>(_ body: (CGImage) throws -> R) rethrows -> R {
        let length = count * MemoryLayout<Pixel>.size

        var image = self
        let provider: CGDataProvider = CGDataProvider(data: Data(
            bytesNoCopy: &image.pixels,
            count: length,
            deallocator: .none
        ) as CFData)!

        let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: MemoryLayout<Pixel._EZ_PixelDirectChannel>.size * 8,
            bitsPerPixel: MemoryLayout<Pixel>.size * 8,
            bytesPerRow: MemoryLayout<Pixel>.size * width,
            space: Pixel._ez_cgColorSpace,
            bitmapInfo: Pixel._ez_cgBitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent
        )!

        return try body(cgImage)
    }

    @inlinable
    public mutating func withCGContext(coordinates: CGContextCoordinates = .natural, _ body: (CGContext) throws -> Void) rethrows {
        let width = self.width
        let height = self.height

        precondition(width >= 0)
        precondition(height >= 0)

        let context  = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: MemoryLayout<Pixel._EZ_PixelDirectChannel>.size * 8,
            bytesPerRow: MemoryLayout<Pixel>.size * width,
            space: Pixel._ez_cgColorSpace,
            bitmapInfo: Pixel._ez_cgBitmapInfo.rawValue
        )!
        switch coordinates {
        case .original:
            break
        case .natural:
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: 0.5, y: 0.5 - CGFloat(height))
        }

        try body(context)
    }
}

extension ImageSlice: _CGImageConvertible where Pixel: _CGPixel {
    @inlinable
    public init(cgImage: CGImage) {
        self.init(Image<Pixel>(cgImage: cgImage))
    }

    @inlinable
    public var cgImage: CGImage {
        return map { $0._ez_directPixel }.cgImage
    }
}

extension ImageSlice: _CGImageDirectlyConvertible where Pixel: _CGDirectPixel {
    @inlinable
    public var cgImage: CGImage {
        let imageCount = image.count
        let pixelCount = image.width * self.height
        let length = pixelCount * MemoryLayout<Pixel>.size
        let offset = yRange.lowerBound * image.width + xRange.lowerBound

        var data: Data
        if offset + pixelCount <= imageCount {
            let bytes: UnsafeMutablePointer<Pixel> = UnsafeMutablePointer(mutating: image.pixels) + (yRange.lowerBound * image.width + xRange.lowerBound)
            data = Data(bytes: bytes, count: length)
        } else {
            let bytes: UnsafeMutablePointer<Pixel> = UnsafeMutablePointer(mutating: image.pixels) + (yRange.lowerBound * image.width + xRange.lowerBound)
            let pointer: UnsafeMutablePointer<UInt8> = UnsafeMutableRawPointer(bytes).bindMemory(to: UInt8.self, capacity: length)
            data = Data(capacity: pixelCount * MemoryLayout<Pixel>.size)
            data.append(pointer, count: (imageCount - offset) * MemoryLayout<Pixel>.size)
            data.append(pointer, count: (offset + pixelCount - imageCount) * MemoryLayout<Pixel>.size)
        }

        let provider: CGDataProvider = CGDataProvider(data: data as CFData)!

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: MemoryLayout<Pixel._EZ_PixelDirectChannel>.size * 8,
            bitsPerPixel: MemoryLayout<Pixel>.size * 8,
            bytesPerRow: MemoryLayout<Pixel>.size * image.width,
            space: Pixel._ez_cgColorSpace,
            bitmapInfo: Pixel._ez_cgBitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent
        )!
    }

    @inlinable
    public func withCGImage<R>(_ body: (CGImage) throws -> R) rethrows -> R {
        let length = image.width * self.height * MemoryLayout<Pixel>.size

        var slice = self
        let bytes: UnsafeMutablePointer<Pixel> = &slice.image.pixels + (slice.yRange.lowerBound * slice.image.width + slice.xRange.lowerBound)
        let provider: CGDataProvider = CGDataProvider(data: Data(
            bytesNoCopy: bytes,
            count: length,
            deallocator: .none
        ) as CFData)!

        let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: MemoryLayout<Pixel._EZ_PixelDirectChannel>.size * 8,
            bitsPerPixel: MemoryLayout<Pixel>.size * 8,
            bytesPerRow: MemoryLayout<Pixel>.size * image.width,
            space: Pixel._ez_cgColorSpace,
            bitmapInfo: Pixel._ez_cgBitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent
        )!

        return try body(cgImage)

    }

    @inlinable
    public mutating func withCGContext(coordinates: CGContextCoordinates = .natural, _ body: (CGContext) throws -> Void) rethrows {
        let width = self.width
        let height = self.height

        precondition(width >= 0)
        precondition(height >= 0)

        let data: UnsafeMutablePointer<Pixel> = &self.image.pixels + (yRange.lowerBound * self.image.width + xRange.lowerBound)
        let context  = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: MemoryLayout<Pixel._EZ_PixelDirectChannel>.size * 8,
            bytesPerRow: MemoryLayout<Pixel>.size * self.image.width,
            space: Pixel._ez_cgColorSpace,
            bitmapInfo: Pixel._ez_cgBitmapInfo.rawValue
        )!
        switch coordinates {
        case .original:
            break
        case .natural:
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: 0.5 - CGFloat(xRange.lowerBound), y: 0.5 - CGFloat(yRange.lowerBound + height))
        }

        try body(context)
    }
}
#endif

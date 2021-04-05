import Metal

public protocol MetalCompatibleScalar {
    static var scalarType: MTLPixelFormat.ScalarType { get }
    static var maximum: MetalCompatibleScalar { get }
    static var minimum: MetalCompatibleScalar { get }
}

extension Float32: MetalCompatibleScalar {
    public static var scalarType: MTLPixelFormat.ScalarType { .float }
    public static var maximum: MetalCompatibleScalar { Self.greatestFiniteMagnitude }
    public static var minimum: MetalCompatibleScalar { Self.leastNormalMagnitude }
}
@available(iOS 14.0, *)
extension Swift.Float16: MetalCompatibleScalar  {
    public static var scalarType: MTLPixelFormat.ScalarType { .half }
    public static var maximum: MetalCompatibleScalar { Self.greatestFiniteMagnitude }
    public static var minimum: MetalCompatibleScalar { Self.leastNormalMagnitude }
}
extension UInt32: MetalCompatibleScalar  {
    public static var scalarType: MTLPixelFormat.ScalarType { .uint }
    public static var maximum: MetalCompatibleScalar { Self.max }
    public static var minimum: MetalCompatibleScalar { Self.min }
}
extension UInt16: MetalCompatibleScalar  {
    public static var scalarType: MTLPixelFormat.ScalarType { .ushort }
    public static var maximum: MetalCompatibleScalar { Self.max }
    public static var minimum: MetalCompatibleScalar { Self.min }
}
extension Int32: MetalCompatibleScalar  {
    public static var scalarType: MTLPixelFormat.ScalarType { .int }
    public static var maximum: MetalCompatibleScalar { Self.max }
    public static var minimum: MetalCompatibleScalar { Self.min }
}
extension Int16: MetalCompatibleScalar  {
    public static var scalarType: MTLPixelFormat.ScalarType { .short }
    public static var maximum: MetalCompatibleScalar { Self.max }
    public static var minimum: MetalCompatibleScalar { Self.min }
}

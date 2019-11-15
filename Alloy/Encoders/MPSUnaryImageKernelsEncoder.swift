//
//  MPSUnaryImageKernelsEncoder.swift
//  Alloy
//
//  Created by Eugene Bokhan on 27.09.2019.
//

import MetalPerformanceShaders

@available(iOS 11.3, *)
final public class MPSUnaryImageKernelsEncoder {

    public enum MPSUnaryImageKernels {
        public enum MPSImagePyramidInitType {
            case centerWeight(centerWeight: Float)
            case kernelWeights(kernelWidth: Int,
                               kernelHeight: Int,
                               kernelWeights: UnsafePointer<Float>)
        }

        case conversion(srcAlpha: MPSAlphaType,
                        destAlpha: MPSAlphaType,
                        backgroundColor: UnsafeMutablePointer<CGFloat>?,
                        conversionInfo: CGColorConversionInfo?)
        case convolution(kernelWidth: Int,
                         kernelHeight: Int,
                         weights: UnsafePointer<Float>,
                         bias: Float = 0)
        case laplacian(bias: Float = 0)
        case box(kernelWidth: Int,
                 kernelHeight: Int)
        case tent(kernelWidth: Int,
                  kernelHeight: Int)
        case gaussianBlur(sigma: Float)
        case sobel(linearGrayColorTransform: UnsafePointer<Float>)
        case gaussianPyramid(initType: MPSImagePyramidInitType)
        case laplacianPyramid(initType: MPSImagePyramidInitType,
                              laplacianBias: Float = 0,
                              laplacianScale: Float = 1)
        case laplacianPyramidSubtract(initType: MPSImagePyramidInitType,
                                      laplacianBias: Float = 0,
                                      laplacianScale: Float = 1)
        case laplacianPyramidAdd(initType: MPSImagePyramidInitType,
                                 laplacianBias: Float = 0,
                                 laplacianScale: Float = 1)
        case euclideanDistanceTransform
        case integral
        case integralOfSquares
        case median(kernelDiameter: Int)
        case areaMax(kernelWidth: Int,
                     kernelHeight: Int)
        case areaMin(kernelWidth: Int,
                     kernelHeight: Int)
        case dilate(kernelWidth: Int,
                    kernelHeight: Int,
                    values: UnsafePointer<Float>)
        case erode(kernelWidth: Int,
                   kernelHeight: Int,
                   values: UnsafePointer<Float>)
        case reduceRowMin
        case reduceColumnMin
        case reduceRowMax
        case reduceColumnMax
        case reduceRowMean
        case reduceColumnMean
        case reduceRowSum
        case reduceColumnSum
        case lanczosScale(scaleTransform: UnsafePointer<MPSScaleTransform>? = nil)
        case bilinearScale(scaleTransform: UnsafePointer<MPSScaleTransform>? = nil)
        case statisticsMinAndMax
        case statisticsMeanAndVariance
        case statisticsMean
        case thresholdBinary(thresholdValue: Float,
                             maximumValue: Float,
                             linearGrayColorTransform: UnsafePointer<Float>? = nil)
        case thresholdBinaryInverse(thresholdValue: Float,
                                    maximumValue: Float,
                                    linearGrayColorTransform: UnsafePointer<Float>? = nil)
        case thresholdTruncate(thresholdValue: Float,
                               linearGrayColorTransform: UnsafePointer<Float>? = nil)
        case thresholdToZero(thresholdValue: Float,
                             linearGrayColorTransform: UnsafePointer<Float>? = nil)
        case thresholdToZeroInverse(thresholdValue: Float,
                                   linearGrayColorTransform: UnsafePointer<Float>? = nil)
        case transpose

        func kernel(device: MTLDevice) -> MPSUnaryImageKernel {
            switch self {
            case .conversion(let srcAlpha,
                             let destAlpha,
                             let backgroundColor,
                             let conversionInfo):
                return MPSImageConversion(device: device,
                                          srcAlpha: srcAlpha,
                                          destAlpha: destAlpha,
                                          backgroundColor: backgroundColor,
                                          conversionInfo: conversionInfo)
            case .convolution(let kernelWidth,
                              let kernelHeight,
                              let weights,
                              let bias):
                let kernel = MPSImageConvolution(device: device,
                                                 kernelWidth: kernelWidth,
                                                 kernelHeight: kernelHeight,
                                                 weights: weights)
                kernel.bias = bias
                return kernel
            case .laplacian(let bias):
                let kernel = MPSImageLaplacian(device: device)
                kernel.bias = bias
                return kernel
            case .box(let kernelWidth, let kernelHeight):
                return MPSImageBox(device: device,
                                   kernelWidth: kernelWidth,
                                   kernelHeight: kernelHeight)
            case .tent(let kernelWidth, let kernelHeight):
                return MPSImageTent(device: device,
                                    kernelWidth: kernelWidth,
                                    kernelHeight: kernelHeight)
            case .gaussianBlur(let sigma):
                return MPSImageGaussianBlur(device: device,
                                            sigma: sigma)
            case .sobel(let linearGrayColorTransform):
                return MPSImageSobel(device: device,
                                     linearGrayColorTransform: linearGrayColorTransform)
            case .gaussianPyramid(let initType):
                switch initType {
                case .centerWeight(let centerWeight):
                    return MPSImageGaussianPyramid(device: device,
                                                   centerWeight: centerWeight)
                case .kernelWeights(let kernelWidth,
                                    let kernelHeight,
                                    let kernelWeights):
                    return MPSImageGaussianPyramid(device: device,
                                                   kernelWidth: kernelWidth,
                                                   kernelHeight: kernelHeight,
                                                   weights: kernelWeights)
                }
            case .laplacianPyramid(let initType,
                                   let laplacianBias,
                                   let laplacianScale):
                switch initType {
                case .centerWeight(let centerWeight):
                    let kernel = MPSImageLaplacianPyramid(device: device,
                                                          centerWeight: centerWeight)
                    kernel.laplacianBias = laplacianBias
                    kernel.laplacianScale = laplacianScale
                    return kernel
                case .kernelWeights(let kernelWidth,
                                    let kernelHeight,
                                    let kernelWeights):
                    let kernel = MPSImageLaplacianPyramid(device: device,
                                                          kernelWidth: kernelWidth,
                                                          kernelHeight: kernelHeight,
                                                          weights: kernelWeights)
                    kernel.laplacianBias = laplacianBias
                    kernel.laplacianScale = laplacianScale
                    return kernel
                }
            case .laplacianPyramidSubtract(let initType,
                                           let laplacianBias,
                                           let laplacianScale):
                switch initType {
                case .centerWeight(let centerWeight):
                    let kernel = MPSImageLaplacianPyramidSubtract(device: device,
                                                                  centerWeight: centerWeight)
                    kernel.laplacianBias = laplacianBias
                    kernel.laplacianScale = laplacianScale
                    return kernel
                case .kernelWeights(let kernelWidth,
                                    let kernelHeight,
                                    let kernelWeights):
                    let kernel = MPSImageLaplacianPyramidSubtract(device: device,
                                                                  kernelWidth: kernelWidth,
                                                                  kernelHeight: kernelHeight,
                                                                  weights: kernelWeights)
                    kernel.laplacianBias = laplacianBias
                    kernel.laplacianScale = laplacianScale
                    return kernel
                }
            case .laplacianPyramidAdd(let initType,
                                      let laplacianBias,
                                      let laplacianScale):
                switch initType {
                case .centerWeight(let centerWeight):
                    let kernel = MPSImageLaplacianPyramidAdd(device: device,
                                                             centerWeight: centerWeight)
                    kernel.laplacianBias = laplacianBias
                    kernel.laplacianScale = laplacianScale
                    return kernel
                case .kernelWeights(let kernelWidth,
                                    let kernelHeight,
                                    let kernelWeights):
                    let kernel = MPSImageLaplacianPyramidAdd(device: device,
                                                             kernelWidth: kernelWidth,
                                                             kernelHeight: kernelHeight,
                                                             weights: kernelWeights)
                    kernel.laplacianBias = laplacianBias
                    kernel.laplacianScale = laplacianScale
                    return kernel
                }
            case .euclideanDistanceTransform:
                return MPSImageEuclideanDistanceTransform(device: device)
            case .integral:
                return MPSImageIntegral(device: device)

            case .integralOfSquares:
                return MPSImageIntegralOfSquares(device: device)
            case .median(let kernelDiameter):
                return MPSImageMedian(device: device,
                                      kernelDiameter: kernelDiameter)
            case .areaMax(let kernelWidth,
                          let kernelHeight):
                return MPSImageAreaMax(device: device,
                                       kernelWidth: kernelWidth,
                                       kernelHeight: kernelHeight)
            case .areaMin(let kernelWidth,
                          let kernelHeight):
                return MPSImageAreaMin(device: device,
                                       kernelWidth: kernelWidth,
                                       kernelHeight: kernelHeight)

            case .dilate(let kernelWidth,
                         let kernelHeight,
                         let values):
                return MPSImageDilate(device: device,
                                      kernelWidth: kernelWidth,
                                      kernelHeight: kernelHeight,
                                      values: values)
            case .erode(let kernelWidth,
                        let kernelHeight,
                        let values):
                return MPSImageErode(device: device,
                                     kernelWidth: kernelWidth,
                                     kernelHeight: kernelHeight,
                                     values: values)
            case .reduceRowMin:
                return MPSImageReduceRowMin(device: device)
            case .reduceColumnMin:
                return MPSImageReduceColumnMin(device: device)
            case .reduceRowMax:
                return MPSImageReduceRowMax(device: device)
            case .reduceColumnMax:
                return MPSImageReduceColumnMax(device: device)
            case .reduceRowMean:
                return MPSImageReduceRowMean(device: device)
            case .reduceColumnMean:
                return MPSImageReduceColumnMean(device: device)
            case .reduceRowSum:
                return MPSImageReduceRowSum(device: device)
            case .reduceColumnSum:
                return MPSImageReduceColumnSum(device: device)
            case .lanczosScale(let scaleTransform):
                let kernel = MPSImageLanczosScale(device: device)
                kernel.scaleTransform = scaleTransform
                return kernel
            case .bilinearScale(let scaleTransform):
                let kernel = MPSImageBilinearScale(device: device)
                kernel.scaleTransform = scaleTransform
                return kernel
            case .statisticsMinAndMax:
                return MPSImageStatisticsMinAndMax(device: device)
            case .statisticsMeanAndVariance:
                return MPSImageStatisticsMeanAndVariance(device: device)
            case .statisticsMean:
                return MPSImageStatisticsMean(device: device)
            case .thresholdBinary(let thresholdValue,
                                  let maximumValue,
                                  let linearGrayColorTransform):
                return MPSImageThresholdBinary(device: device,
                                               thresholdValue: thresholdValue,
                                               maximumValue: maximumValue,
                                               linearGrayColorTransform: linearGrayColorTransform)
            case .thresholdBinaryInverse(let thresholdValue,
                                         let maximumValue,
                                         let linearGrayColorTransform):
                return MPSImageThresholdBinaryInverse(device: device,
                                                      thresholdValue: thresholdValue,
                                                      maximumValue: maximumValue,
                                                      linearGrayColorTransform: linearGrayColorTransform)
            case .thresholdTruncate(let thresholdValue,
                                    let linearGrayColorTransform):
                return MPSImageThresholdTruncate(device: device,
                                                 thresholdValue: thresholdValue,
                                                 linearGrayColorTransform: linearGrayColorTransform)
            case .thresholdToZero(let thresholdValue,
                                  let linearGrayColorTransform):
                return MPSImageThresholdToZero(device: device,
                                               thresholdValue: thresholdValue,
                                               linearGrayColorTransform: linearGrayColorTransform)
            case .thresholdToZeroInverse(let thresholdValue,
                                         let linearGrayColorTransform):
                return MPSImageThresholdToZeroInverse(device: device,
                                                      thresholdValue: thresholdValue,
                                                      linearGrayColorTransform: linearGrayColorTransform)
            case .transpose:
                return MPSImageTranspose(device: device)
            }
        }
    }

    // MARK: - Properties

    public let kernelQueue: [MPSUnaryImageKernel]

    // MARK: - Life Cycle

    public init(device: MTLDevice,
                kernelQueue: [MPSUnaryImageKernels]) {
        self.kernelQueue = kernelQueue.map { $0.kernel(device: device) }
    }

    // MARK: - Encode

    public func encode(sourceTexture: MTLTexture,
                       destinationTexture: MTLTexture,
                       commandBuffer: MTLCommandBuffer) {
        if self.kernelQueue.count == 0 { return }

        let textureDescriptor = sourceTexture.descriptor
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .private
        let temporaryImages = [Int](0 ..< self.kernelQueue.count).map { _ in
            MPSTemporaryImage(commandBuffer: commandBuffer,
                              textureDescriptor: textureDescriptor)
        }
        defer { temporaryImages.forEach { $0.readCount = 0 } }
        var textures = temporaryImages.map { $0.texture }
        textures.insert(sourceTexture, at: 0)
        textures.append(destinationTexture)

        for i in 0 ..< self.kernelQueue.count {
            let kernel = self.kernelQueue[i]
            let sourceTexture = textures[i]
            let destinationTexture = textures[i + 1]
            kernel.encode(commandBuffer: commandBuffer,
                          sourceTexture: sourceTexture,
                          destinationTexture: destinationTexture)
        }
    }
}

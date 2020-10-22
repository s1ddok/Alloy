#ifndef PRBShaderLib_h
#define PRBShaderLib_h

#if __METAL_MACOS__ || __METAL_IOS__

#include <metal_stdlib>

using namespace metal;

#endif /* __METAL_MACOS__ || __METAL_IOS__ */

#import <simd/simd.h>

#if __METAL_MACOS__ || __METAL_IOS__

namespace beauty {
    METAL_FUNC float hue2rgb(float p, float q, float t){
        if(t < 0.0) {
            t += 1.0;
        }
        if(t > 1.0) {
            t -= 1.0;
        }
        if(t < 1.0/6.0) {
            return p + (q - p) * 6.0 * t;
        }
        if(t < 1.0/2.0) {
            return q;
        }
        if(t < 2.0/3.0) {
            return p + (q - p) * (2.0/3.0 - t) * 6.0;
        }
        return p;
    }
    
    METAL_FUNC float3 rgb2hsl(float3 inputColor) {
        float3 color = saturate(inputColor);
        
        //Compute min and max component values
        float MAX = max(color.r, max(color.g, color.b));
        float MIN = min(color.r, min(color.g, color.b));
        
        //Make sure MAX > MIN to avoid division by zero later
        MAX = max(MIN + 1e-6, MAX);
        
        //Compute luminosity
        float l = (MIN + MAX) / 2.0;
        
        //Compute saturation
        float s = (l < 0.5 ? (MAX - MIN) / (MIN + MAX) : (MAX - MIN) / (2.0 - MAX - MIN));
        
        //Compute hue
        float h = (MAX == color.r ? (color.g - color.b) / (MAX - MIN) : (MAX == color.g ? 2.0 + (color.b - color.r) / (MAX - MIN) : 4.0 + (color.r - color.g) / (MAX - MIN)));
        h /= 6.0;
        h = (h < 0.0 ? 1.0 + h : h);
        
        return float3(h, s, l);
    }
    
    METAL_FUNC float3 hsl2rgb(float3 inputColor) {
        float3 color = saturate(inputColor);
        
        float h = color.r;
        float s = color.g;
        float l = color.b;
        
        float r,g,b;
        if(s <= 0.0){
            r = g = b = l;
        }else{
            float q = l < 0.5 ? (l * (1.0 + s)) : (l + s - l * s);
            float p = 2.0 * l - q;
            r = hue2rgb(p, q, h + 1.0/3.0);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1.0/3.0);
        }
        return float3(r,g,b);
    }
    
    
    METAL_FUNC float3 rgb2hsv(float3 c) {
        const float4 K = float4(0.0f, -1.0f / 3.0f, 2.0f / 3.0f, -1.0f);
        const float4 p = mix(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
        const float4 q = mix(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
        const float d = q.x - min(q.w, q.y);
        const float e = 1.0e-10f;
        return float3(abs(q.z + (q.w - q.y) / (6.0f * d + e)), d / (q.x + e), q.x);
    }
    
    METAL_FUNC half3 rgb2hsv(half3 c) {
        const half4 K = half4(0.0h, -1.0h / 3.0h, 2.0h / 3.0h, -1.0h);
        const half4 p = mix(half4(c.bg, K.wz), half4(c.gb, K.xy), step(c.b, c.g));
        const half4 q = mix(half4(p.xyw, c.r), half4(c.r, p.yzx), step(p.x, c.r));
        const half d = q.x - min(q.w, q.y);
        const half e = 5.9605E-8h;
        return half3(abs(q.z + (q.w - q.y) / (6.0h * d + e)), d / (q.x + e), q.x);
    }
    
    METAL_FUNC float3 hsv2rgb(float3 c) {
        const float4 K = float4(1.0f, 2.0f / 3.0f, 1.0f / 3.0f, 3.0f);
        const float3 p = abs(fract(c.xxx + K.xyz) * 6.0f - K.www);
        return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0f, 1.0f), c.y);
    }
    
    METAL_FUNC float3 rgb2xyz( float3 c ) {
        float3 tmp;
        tmp.x = ( c.r > 0.04045 ) ? pow( ( c.r + 0.055 ) / 1.055, 2.4 ) : c.r / 12.92;
        tmp.y = ( c.g > 0.04045 ) ? pow( ( c.g + 0.055 ) / 1.055, 2.4 ) : c.g / 12.92,
        tmp.z = ( c.b > 0.04045 ) ? pow( ( c.b + 0.055 ) / 1.055, 2.4 ) : c.b / 12.92;
        const float3x3 mat = float3x3(
                                      float3( 0.4124, 0.3576, 0.1805 ),
                                      float3( 0.2126, 0.7152, 0.0722 ),
                                      float3( 0.0193, 0.1192, 0.9505 )
                                      );
        return 100.0f * (tmp * mat);
    }
    
    METAL_FUNC float3 xyz2lab( float3 c ) {
        float3 n = c / float3(95.047, 100, 108.883);
        float3 v;
        v.x = ( n.x > 0.008856 ) ? pow( n.x, 1.0 / 3.0 ) : ( 7.787 * n.x ) + ( 16.0 / 116.0 );
        v.y = ( n.y > 0.008856 ) ? pow( n.y, 1.0 / 3.0 ) : ( 7.787 * n.y ) + ( 16.0 / 116.0 );
        v.z = ( n.z > 0.008856 ) ? pow( n.z, 1.0 / 3.0 ) : ( 7.787 * n.z ) + ( 16.0 / 116.0 );
        return float3(( 116.0 * v.y ) - 16.0, 500.0 * ( v.x - v.y ), 200.0 * ( v.y - v.z ));
    }
    
    METAL_FUNC float3 rgb2lab( float3 c ) {
        float3 lab = xyz2lab( rgb2xyz( c ) );
        return float3( lab.x / 100.0, 0.5 + 0.5 * ( lab.y / 127.0 ), 0.5 + 0.5 * ( lab.z / 127.0 ));
    }
    
    METAL_FUNC float3 lab2xyz( float3 c ) {
        float fy = ( c.x + 16.0 ) / 116.0;
        float fx = c.y / 500.0 + fy;
        float fz = fy - c.z / 200.0;
        return float3(
                      95.047 * (( fx > 0.206897 ) ? fx * fx * fx : ( fx - 16.0 / 116.0 ) / 7.787),
                      100.000 * (( fy > 0.206897 ) ? fy * fy * fy : ( fy - 16.0 / 116.0 ) / 7.787),
                      108.883 * (( fz > 0.206897 ) ? fz * fz * fz : ( fz - 16.0 / 116.0 ) / 7.787)
                      );
    }
    
    METAL_FUNC float3 xyz2rgb( float3 c ) {
        const float3x3 mat = float3x3(
                                      float3( 3.2406, -1.5372, -0.4986 ),
                                      float3( -0.9689, 1.8758, 0.0415 ),
                                      float3( 0.0557, -0.2040, 1.0570 )
                                      );
        float3 v = (c / 100.0f) * mat;
        float3 r;
        r.x = ( v.r > 0.0031308 ) ? (( 1.055 * pow( v.r, ( 1.0 / 2.4 ))) - 0.055 ) : 12.92 * v.r;
        r.y = ( v.g > 0.0031308 ) ? (( 1.055 * pow( v.g, ( 1.0 / 2.4 ))) - 0.055 ) : 12.92 * v.g;
        r.z = ( v.b > 0.0031308 ) ? (( 1.055 * pow( v.b, ( 1.0 / 2.4 ))) - 0.055 ) : 12.92 * v.b;
        return r;
    }
    
    METAL_FUNC float3 lab2rgb( float3 c ) {
        return xyz2rgb( lab2xyz( float3(100.0 * c.x, 2.0 * 127.0 * (c.y - 0.5), 2.0 * 127.0 * (c.z - 0.5)) ) );
    }
}

#endif /* __METAL_MACOS__ || __METAL_IOS__ */

#endif /* ColorConversion_h */

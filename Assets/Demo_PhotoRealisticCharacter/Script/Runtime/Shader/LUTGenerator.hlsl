#ifndef LUT_GENERATOR_INCLUDED
#define LUT_GENERATOR_INCLUDED

    #define PI 3.14159265359
    #define MAX_ITERATION 360
    #define WRAP 0

    // Gaussian Function
    float Gaussian ( float v , float r )
    {
        return 1.0 / sqrt (2.0 * PI * v ) * exp(- (r * r) / 2.0 / v);
    }

    // to approximate the skin diffustion profile with six Gaussian functions for each channel
    float3 DiffusionProfile(float r)
    {
        return Gaussian ( 0.0064 * 1.414 , r ) * float3( 0.233 , 0.455 , 0.649 ) +
    	        Gaussian ( 0.0484 * 1.414 , r ) * float3( 0.100 , 0.336 , 0.344 ) +
    	        Gaussian ( 0.1870 * 1.414 , r ) * float3( 0.118 , 0.198 , 0.000 ) +
    	        Gaussian ( 0.5670 * 1.414 , r ) * float3( 0.113 , 0.007 , 0.007 ) +
    	        Gaussian ( 1.9900 * 1.414 , r ) * float3( 0.358 , 0.004 , 0.000 ) +
    	        Gaussian ( 7.4100 * 1.414 , r ) * float3( 0.078 , 0.000 , 0.000 ) ;
    }

    float3 GenerateDiffuseLUT(float theta, float curvature)
    {
        float3 normFactor = 0.0;
        float3 warppedLight = 0.0;
    
        float r = 1. / curvature; // radius: [1, inf]
    
        float angleInterval = 2. * PI / float(MAX_ITERATION);
    
        for(int i = 0; i < MAX_ITERATION; i += 1){
            float deltaX = float(i) * angleInterval;
            float dist = abs(2. * r * sin(deltaX * 0.5));
        
            float3 weight = DiffusionProfile(dist);
        
            float irradiance = (cos(theta + deltaX) + WRAP) / (1.+ WRAP);
            irradiance = max(0., irradiance);
            warppedLight += irradiance * weight;
            normFactor += weight;
        }
    
        return warppedLight / normFactor;
    }

    float3 T(float s) 
    {
        return float3(0.233, 0.455, 0.649) * exp(-s * s / 0.0064) +
               float3(0.1, 0.336, 0.344) * exp(-s * s / 0.0484) +
               float3(0.118, 0.198, 0.0) * exp(-s * s / 0.187) +
               float3(0.113, 0.007, 0.007) * exp(-s * s / 0.567) +
               float3(0.358, 0.004, 0.0) * exp(-s * s / 1.99) +
               float3(0.078, 0.0, 0.0) * exp(-s * s / 7.41);
    }

#endif 
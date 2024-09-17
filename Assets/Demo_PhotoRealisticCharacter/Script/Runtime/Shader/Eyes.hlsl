#ifndef EYES_INCLUDED
#define EYES_INCLUDED

    float2 ParallaxOffset_K(float height, float parallaxScale, float3 view)
    {
        float2 offset = height * view;
        //offset.y = -offset.y;
        return parallaxScale * offset;
    }

#endif 
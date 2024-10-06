#ifndef FAST_MATH_THIRD_PARTY_INCLUDED
#define FAST_MATH_THIRD_PARTY_INCLUDED

    float Pow2(float x)
    {
        return x * x;
    }

    float Pow5(float x)
    {
        return x * x * x * x * x;
    }

    float acosFast(float inX) 
    {
        float x = abs(inX);
        float res = -0.156583f * x + (0.5 * PI);
        res *= sqrt(1.0f - x);
        return (inX >= 0) ? res : PI - res;
    }

    float asinFast( float x )
    {
        return (0.5 * PI) - acosFast(x);
    }

#endif 
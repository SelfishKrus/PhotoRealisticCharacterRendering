# PhotoRealisticCharacterRendering
A custom shading model of photo-realistic character, written in HLSL.
Character model sources from https://www.artstation.com/artwork/AlJZrz, based on which some modification was made to reproduce high-quality real-time rendering in Unity.

https://github.com/user-attachments/assets/4444ead9-2871-4d14-8a46-0b6bff531f27

---
# Shading Model (supports for both directional light and environment light):

Skin: Pre-integrated subsurface scattering, dual-lobe beckmann specular, pre-integrated transmittance;

https://github.com/user-attachments/assets/e6a0fe80-ff87-4fe9-9d7b-cbbb3ca302c7

Hair: Kajiya-Kay specular, empirical multi-scattering and wraping diffuse borrowed from Uncharted4; dithered blending OIT;

Eyes: tearline, eyeball ao, procedural limbus, physically-based refraction parallax, empirical caustic, sclera sss and reflection

https://github.com/user-attachments/assets/57d7f6ce-5383-4bb5-a020-ff575a7d1f16

<img width="333" alt="eyeballs" src="https://github.com/user-attachments/assets/6d121a2f-576f-463f-8be8-e51f0ffe9d47">

<img width="1063" alt="Snipaste_2024-10-26_19-58-25" src="https://github.com/user-attachments/assets/18b14653-f1da-479d-851b-21f2cdbc1de5">

---
# About textures:
some created by substance designer, and some is at shadertoy.com

be free to check the procedural map and pre-integrated LUT:

- Beckmann LUT: https://www.shadertoy.com/view/MXfBDl
- Pre-integrated sss LUT: https://www.shadertoy.com/view/Xcsfz8
- Pre-integrated shadow LUT: https://www.shadertoy.com/view/lflBRH
- Sine-based normal map: https://www.shadertoy.com/view/XXfyzn

---
# Ref:

- SIG2016-The Process of Creating Volumetric-based Materials in Uncharted 4
- GDC2013-Next-Generation-Character-Rendering-v6
- GTC14-FaceWorks-Overview
- SIG2011-Pre-IntegratedSkinRendering
- Skin-Real-Time-Realistic-Skin-Translucency
- SIG2016-Physically Based Hair Shading in Unreal
- GDC2004-ATI-HairRenderingAndShading
- SIG2019-Strand-based hair rendering in Frostbite





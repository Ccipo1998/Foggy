using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class FogSystem : MonoBehaviour
{
    [Header("Camera")]
    [SerializeField]
    private Camera _Camera;

    [Header("Shadow map parameters")]

    [SerializeField]
    private Light _SunLight;

    [Header("Fog parameters")]

    [SerializeField]
    private Material _FogMaterial;

    [SerializeField]
    [Range(0, 1.0f)]
    private float _FogDensity;

    [SerializeField]
    [Range(0, 1.0f)]
    private float _ExctinctionCoefficient;

    [SerializeField]
    private Texture2D _FogDensityTexture;

    [SerializeField]
    [Range (0, 2.0f)]
    private float _FogDensityTextureScale;

    [SerializeField]
    private Color _LightColor;

    [SerializeField]
    private float _LightIntensity;

    [SerializeField]
    private Color _AmbientLightColor;

    [SerializeField]
    private float _AmbientLightIntensity;

    [Header("Ray marching parameters")]

    [SerializeField]
    private int _StepsNumber;

    // privates

    private CommandBuffer _shadowmapCommandBuffer;
    private RenderTexture m_ShadowmapCopy;
    private CommandBuffer _afterShadowPass;

    #region SHADER_UNIFORMS

    private static readonly int InverseProjectionMatrix = Shader.PropertyToID("InverseProjectionMatrix");
    private static readonly int InverseViewMatrix = Shader.PropertyToID("InverseViewMatrix");
    private static readonly int FogDensity = Shader.PropertyToID("FogDensity");
    private static readonly int LightColor = Shader.PropertyToID("LightColor");
    private static readonly int LightIntensity = Shader.PropertyToID("LightIntensity");
    private static readonly int AmbientLightIntensity = Shader.PropertyToID("AmbientLightIntensity");
    private static readonly int AmbientLightColor = Shader.PropertyToID("AmbientLightColor");
    private static readonly int FogDensityTexture = Shader.PropertyToID("_FogDensityTexture");
    private static readonly int FogDensityTextureScale = Shader.PropertyToID("FogDensityTextureScale");
    private static readonly int StepsNumber = Shader.PropertyToID("StepsNumber");
    private static readonly int ExctinctionCoefficient = Shader.PropertyToID("ExctinctionCoefficient");

    #endregion

    private void Start()
    {
        // enable depth buffer draw
        _Camera.depthTextureMode = DepthTextureMode.Depth;

        // set shadow map as global texture
        SetGlobalShadowTexture();
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // update matrices
        Shader.SetGlobalMatrix(InverseProjectionMatrix, _Camera.projectionMatrix.inverse);
        Shader.SetGlobalMatrix(InverseViewMatrix, _Camera.cameraToWorldMatrix);

        // update fog parameters
        Shader.SetGlobalFloat(FogDensity, Mathf.Pow(_FogDensity, 3.0f)); // to the power of 3 to resize density values in editor
        Shader.SetGlobalColor(LightColor, _LightColor);
        Shader.SetGlobalColor(AmbientLightColor, _AmbientLightColor);
        Shader.SetGlobalFloat(LightIntensity, _LightIntensity);
        Shader.SetGlobalFloat(AmbientLightIntensity, _AmbientLightIntensity);
        Shader.SetGlobalTexture(FogDensityTexture, _FogDensityTexture);
        Shader.SetGlobalFloat(FogDensityTextureScale, _FogDensityTextureScale);
        Shader.SetGlobalFloat(ExctinctionCoefficient, Mathf.Pow(_ExctinctionCoefficient, 3.0f));

        // update ray marching parameters
        Shader.SetGlobalInteger(StepsNumber, _StepsNumber);

        // apply shader
        Graphics.Blit(source, destination, _FogMaterial);

        // debug: shadow map draw
        //Graphics.Blit(m_ShadowmapCopy, ShadowMap);
    }

    private void SetGlobalShadowTexture()
    {
        _afterShadowPass = new CommandBuffer { name = "Volumetric Fog ShadowMap" };

        _afterShadowPass.SetGlobalTexture("ShadowMap",
            new RenderTargetIdentifier(BuiltinRenderTextureType.CurrentActive));

        if (_SunLight)
        {
            _SunLight.AddCommandBuffer(LightEvent.AfterShadowMap, _afterShadowPass);
        }
    }
}

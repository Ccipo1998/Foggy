using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class FogSystem : MonoBehaviour
{
    [Header("Camera")]
    [SerializeField]
    private Camera _Camera;

    [Header("Fog parameters")]

    [SerializeField]
    private Material _FogMaterial;

    [SerializeField]
    [Range(0, 1.0f)]
    private float _FogDensity;

    [SerializeField]
    private Texture2D _FogDensityTexture;

    [SerializeField]
    [Range (0, 2.0f)]
    private float _FogDensityTextureScale;

    [SerializeField]
    private Color _FogColor;

    #region SHADER_UNIFORMS

    private static readonly int InverseProjectionMatrix = Shader.PropertyToID("InverseProjectionMatrix");
    private static readonly int InverseViewMatrix = Shader.PropertyToID("InverseViewMatrix");
    private static readonly int FogDensity = Shader.PropertyToID("FogDensity");
    private static readonly int FogColor = Shader.PropertyToID("FogColor");
    private static readonly int FogDensityTexture = Shader.PropertyToID("_FogDensityTexture");
    private static readonly int FogDensityTextureScale = Shader.PropertyToID("FogDensityTextureScale");

    #endregion

    private void Start()
    {
        // enable depth buffer draw
        _Camera.depthTextureMode = DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // update matrices
        Shader.SetGlobalMatrix(InverseProjectionMatrix, _Camera.projectionMatrix.inverse);
        Shader.SetGlobalMatrix(InverseViewMatrix, _Camera.cameraToWorldMatrix);

        // update fog parameters
        Shader.SetGlobalFloat(FogDensity, _FogDensity);
        Shader.SetGlobalColor(FogColor, _FogColor);
        Shader.SetGlobalTexture(FogDensityTexture, _FogDensityTexture);
        Shader.SetGlobalFloat(FogDensityTextureScale, _FogDensityTextureScale);

        // apply shader
        Graphics.Blit(source, destination, _FogMaterial);
    }
}

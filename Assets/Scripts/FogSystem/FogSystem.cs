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
    private Color _FogColor;

    #region SHADER_UNIFORMS

    private static readonly int InverseProjectionMatrix = Shader.PropertyToID("InverseProjectionMatrix");
    private static readonly int InverseViewMatrix = Shader.PropertyToID("InverseViewMatrix");
    private static readonly int FogDensity = Shader.PropertyToID("FogDensity");
    private static readonly int FogColor = Shader.PropertyToID("FogColor");

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

        // apply shader
        Graphics.Blit(source, destination, _FogMaterial);
    }
}

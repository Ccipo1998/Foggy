using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RenderZBuffer : MonoBehaviour
{
    [Header("Camera")]
    [SerializeField]
    private Camera _Camera;

    [Header("Render Target")]
    [SerializeField]
    private RenderTexture _ZBufferTexture;
    [SerializeField]
    private Material _ZBufferMaterial;
    
    private void Start()
    {
        // enable depth buffer draw
        _Camera.depthTextureMode = DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, _ZBufferMaterial);
        Graphics.Blit(source, _ZBufferTexture, _ZBufferMaterial);
    }
}

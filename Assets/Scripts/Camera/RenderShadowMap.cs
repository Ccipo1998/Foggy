using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class RenderShadowMap : MonoBehaviour
{
    [Header("Camera")]
    [SerializeField]
    private Camera _Camera;

    [Header("Light")]
    [SerializeField]
    private Light _Light;

    [Header("Render Target")]
    [SerializeField]
    private RenderTexture _ShadowMapTexture;
    [SerializeField]
    private Material _ShadowMapMaterial;

    private RenderTexture m_ShadowmapCopy;

    private void Start()
    {
        RenderTargetIdentifier shadowmap = BuiltinRenderTextureType.CurrentActive;
        m_ShadowmapCopy = new RenderTexture(1024, 1024, 0);
        CommandBuffer cb = new CommandBuffer();

        // Change shadow sampling mode for m_Light's shadowmap.
        cb.SetShadowSamplingMode(shadowmap, ShadowSamplingMode.RawDepth);

        // The shadowmap values can now be sampled normally - copy it to a different render texture.
        cb.Blit(shadowmap, new RenderTargetIdentifier(m_ShadowmapCopy));

        // Execute after the shadowmap has been filled.
        _Light.AddCommandBuffer(LightEvent.AfterShadowMap, cb);

        // Sampling mode is restored automatically after this command buffer completes, so shadows will render normally.
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // Display the shadowmap in the corner.
        //_Camera.rect = new Rect(0, 0, 0.5f, 0.5f);
        Graphics.Blit(m_ShadowmapCopy, destination);
        //_Camera.rect = new Rect(0, 0, 1, 1);
    }
}

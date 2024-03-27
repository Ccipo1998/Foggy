using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.GlobalIllumination;
using UnityEngine.Rendering;

public class ShadowMapSetup : MonoBehaviour
{
    //private CommandBuffer m_afterShadowPass = null;

    //public Light light;

    //// Use this for initialization
    //void Start()
    //{
    //    m_afterShadowPass = new CommandBuffer();
    //    m_afterShadowPass.name = "ShadowMap Command";

    //    //The name of the shadowmap for this light will be "MyShadowMap"
    //    m_afterShadowPass.SetGlobalTexture("ShadowMap", new RenderTargetIdentifier(BuiltinRenderTextureType.CurrentActive));

    //    if (light)
    //    {
    //        //add command buffer right after the shadowmap has been renderered
    //        light.AddCommandBuffer(LightEvent.AfterShadowMap, m_afterShadowPass);
    //    }

    //}


}

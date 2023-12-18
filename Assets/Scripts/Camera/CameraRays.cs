using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraRays : MonoBehaviour
{
    [Header("Rays parameters")]
    [SerializeField]
    private int _HorizontalRaysNumber;
    [SerializeField]
    private int _VerticalRaysNumber;

    [Header("Camera")]
    [SerializeField]
    private Camera _Camera;

    private void Start()
    {
        // create rays
        Vector2 screenCoords = new Vector2();
        for (int i = 0; i < _VerticalRaysNumber; ++i)
        {
            for (int j = 0; j < _HorizontalRaysNumber; ++j)
            {
                // take point on viewport plane and make it in world coords
                screenCoords.x = 1.0f / (_HorizontalRaysNumber - 1) * j;
                screenCoords.y = 1.0f / (_VerticalRaysNumber - 1) * i;
                Ray ray = _Camera.ViewportPointToRay(screenCoords);
                Debug.DrawRay(ray.origin, ray.direction, Color.red, 60.0f);
            }
        }
    }
}

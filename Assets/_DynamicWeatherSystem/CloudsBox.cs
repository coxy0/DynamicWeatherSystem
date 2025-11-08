using UnityEngine;

[ExecuteAlways]
public class CloudsBox : MonoBehaviour
{
    public Material material;

    private Vector3 lastPosition;
    private Vector3 lastScale;

    void Update()
    {
        if (!material) return;

        // Only update when something changes
        if (transform.position != lastPosition || transform.localScale != lastScale)
        {
            Vector3 halfScale = transform.localScale * 0.5f;
            material.SetVector("_BoundsMin", transform.position - halfScale);
            material.SetVector("_BoundsMax", transform.position + halfScale);

            lastPosition = transform.position;
            lastScale = transform.localScale;
        }
    }
}

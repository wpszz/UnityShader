using UnityEngine;
using UnityEngine.UI;

[AddComponentMenu("UI/Plus/CurveText")]
[ExecuteInEditMode]
[RequireComponent(typeof(Text))]
public class CurveText : BaseMeshEffect
{
    [Range(5f, 100f)]
    public int intensity = 10;
    [Range(0.5f, 5f)]
    public float timeScale = 1f;

    public override void ModifyMesh(VertexHelper vh)
    {
        if (!IsActive())
            return;

        UIVertex vert = UIVertex.simpleVert;

        int vertCount = vh.currentVertCount;
        if (vertCount <= 0)
            return;
        float delta = 1.0f / vertCount;
        for (int i = 0; i < vertCount; i++)
        {
            vh.PopulateUIVertex(ref vert, i);
            vert.uv1 = new Vector2(delta * i, intensity * 10 + timeScale);
            vh.SetUIVertex(vert, i);
        }
    }
}

using UnityEngine;
using UnityEngine.UI;

[AddComponentMenu("UI/Plus/Outline")]
[ExecuteInEditMode]
[RequireComponent(typeof(Graphic))]
public class UIOutline : BaseMeshEffect
{
    [Range(0f, 1f)]
    public float uvScale = 1f;
    [Range(0.1f, 5f)]
    public float gScale = 1f;
    public Color color = Color.black;

    public override void ModifyMesh(VertexHelper vh)
    {
        if (!IsActive())
            return;

        UIVertex vert = UIVertex.simpleVert;

        int vertCount = vh.currentVertCount;
        if (vertCount <= 0)
            return;
        for (int i = 0; i < vertCount; i++)
        {
            vh.PopulateUIVertex(ref vert, i);
            vert.uv1 = new Vector2(uvScale, gScale);
            vert.tangent = color;
            vh.SetUIVertex(vert, i);
        }
    }
}

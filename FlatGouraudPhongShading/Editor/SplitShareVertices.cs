using UnityEngine;
using UnityEditor;

public class SplitShareVertices : EditorWindow
{
    [MenuItem("GameObject/SplitShareVertices", false, 3)]
    public static void ShowDialog()
    {
        MeshFilter mf = Selection.activeGameObject.GetComponent<MeshFilter>();
        if (mf == null)
        {
            Debug.LogWarning("No MeshFilter Component on the activeGameObject");
            return;
        }

        string savePath = EditorUtility.SaveFilePanelInProject("Save to", Selection.activeGameObject.name, "asset", "split mesh shared vertices and save to disk.");
        if (string.IsNullOrEmpty(savePath))
            return;

        Mesh mesh = Instantiate(mf.sharedMesh) as Mesh;

        int[] triangles = mesh.triangles;
        Vector3[] originVerts = mesh.vertices;
        Vector3[] splitVerts = new Vector3[triangles.Length];
        for (int i = 0; i < triangles.Length; i++)
        {
            splitVerts[i] = originVerts[triangles[i]];
            triangles[i] = i;
        }
        mesh.vertices = splitVerts;
        mesh.triangles = triangles;
        mesh.RecalculateBounds();
        mesh.RecalculateNormals();

        AssetDatabase.CreateAsset(mesh, savePath);
        AssetDatabase.SaveAssets();
    }
}
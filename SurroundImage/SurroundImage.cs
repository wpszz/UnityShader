using UnityEngine;
using UnityEngine.UI;

#if UNITY_EDITOR
using UnityEditor;
using System.Linq;
#endif

public class SurroundImage : Image
{
    [Range(-1f, 1f)]
    public float balanceX = 0f;
    [Range(-1f, 1f)]
    public float balanceY = 0f;

    [Range(0f, 0.2f)]
    public float amplitudeX = 0.05f;

    [Range(0f, 0.2f)]
    public float amplitudeY = 0.03f;

    private int ID_WP_SURROUND;

    protected override void Start()
    {
        base.Start();

        ID_WP_SURROUND = Shader.PropertyToID("WP_SURROUND");

#if UNITY_EDITOR
        //if (m_Material && !string.IsNullOrEmpty(AssetDatabase.GetAssetPath(m_Material)))
        //    m_Material = Instantiate(m_Material);
#endif
    }

    private void Update()
    {
        if (m_Material)
            m_Material.SetVector(ID_WP_SURROUND, new Vector4(balanceX, balanceY, amplitudeX, amplitudeY));
    }
}

#if UNITY_EDITOR
[CustomEditor(typeof(SurroundImage), true)]
[CanEditMultipleObjects]
public class SurroundImageInspector : Editor
{
    SerializedProperty m_Sprite;
    SerializedProperty m_Color;
    SerializedProperty m_Material;

    SerializedProperty balanceX;
    SerializedProperty balanceY;
    SerializedProperty amplitudeX;
    SerializedProperty amplitudeY;

    GUIContent m_CorrectButtonContent;

    void OnEnable()
    {
        m_Sprite = serializedObject.FindProperty("m_Sprite");
        m_Color = serializedObject.FindProperty("m_Color");
        m_Material = serializedObject.FindProperty("m_Material");

        balanceX = serializedObject.FindProperty("balanceX");
        balanceY = serializedObject.FindProperty("balanceY");
        amplitudeX = serializedObject.FindProperty("amplitudeX");
        amplitudeY = serializedObject.FindProperty("amplitudeY");

        m_CorrectButtonContent = new GUIContent("Set Native Size", "Sets the size to match the content.");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        EditorGUILayout.PropertyField(m_Sprite);
        EditorGUILayout.PropertyField(m_Color);
        EditorGUILayout.PropertyField(m_Material);

        EditorGUILayout.PropertyField(balanceX);
        EditorGUILayout.PropertyField(balanceY);
        EditorGUILayout.PropertyField(amplitudeX);
        EditorGUILayout.PropertyField(amplitudeY);

        serializedObject.ApplyModifiedProperties();

        NativeSizeButtonGUI();
    }

    protected void NativeSizeButtonGUI()
    {
        EditorGUILayout.BeginHorizontal();
        {
            GUILayout.Space(EditorGUIUtility.labelWidth);
            if (GUILayout.Button(m_CorrectButtonContent, EditorStyles.miniButton))
            {
                foreach (Graphic graphic in targets.Select(obj => obj as Graphic))
                {
                    Undo.RecordObject(graphic.rectTransform, "Set Native Size");
                    graphic.SetNativeSize();
                    EditorUtility.SetDirty(graphic);
                }
            }
        }
        EditorGUILayout.EndHorizontal();
    }
}
#endif


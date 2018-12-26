using System;
using UnityEngine;
using UnityEngine.AI;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditorInternal;
#endif

[RequireComponent(typeof(Camera))]
public class WPOutline : MonoBehaviour
{
    [Range(1, 3)]
    public int accuracy = 2;

    [Range(0f, 1f)]
    public float outlineIntensity = 0.5f;

    [Range(0.1f, 10f)]
    public float outlinePower = 3f;

    public Color outlineColor = Color.cyan;

    public bool autoControl;

    public LayerMask cullingMask;
    public Shader depthNormalMapShader;

    private Camera m_depthNormalCamera;
    private Camera depthNormal
    {
        get
        {
            if (null == m_depthNormalCamera)
            {
                Transform node = new GameObject("Depth Normal Map Camera").transform;
                node.SetParent(transform);
                node.localPosition = Vector3.zero;
                node.localRotation = Quaternion.identity;
                node.localScale = Vector3.one;
                m_depthNormalCamera = node.gameObject.AddComponent<Camera>();
                m_depthNormalCamera.enabled = false;
                m_depthNormalCamera.clearFlags = CameraClearFlags.SolidColor;
                m_depthNormalCamera.backgroundColor = Color.black;
                m_depthNormalCamera.renderingPath = RenderingPath.VertexLit;
                m_depthNormalCamera.hdr = false;
                m_depthNormalCamera.useOcclusionCulling = false;
            }
            return m_depthNormalCamera;
        }
    }

    Camera m_mainCamera;
    RenderTexture m_depthNormalMap;

    int m_depthNormalMapSize;

    private int ID_WP_DepthNormalMap;
    private int ID_WP_OutlineParams;
    private int ID_WP_OutlineColor;

    private void Awake()
    {
        if (!depthNormalMapShader)
            FixShadowMapShader();
    }

    private void Start()
    {
        ID_WP_DepthNormalMap = Shader.PropertyToID("WP_DepthNormalMap");
        ID_WP_OutlineParams = Shader.PropertyToID("WP_OutlineParams");
        ID_WP_OutlineColor = Shader.PropertyToID("WP_OutlineColor");

        m_mainCamera = this.GetComponent<Camera>();

        if (!m_mainCamera || !depthNormalMapShader)
        {
            this.enabled = false;
            return;
        }
    }

    private void OnDestroy()
    {
        ClearOutline();

        if (m_depthNormalCamera)
            GameObject.Destroy(m_depthNormalCamera);
        m_depthNormalCamera = null;
    }

    private void OnDisable()
    {
        ClearOutline();
    }

    private void ClearOutline()
    {
        if (m_depthNormalMap)
            RenderTexture.ReleaseTemporary(m_depthNormalMap);
        m_depthNormalMap = null;
        m_depthNormalMapSize = 0;
        Shader.SetGlobalTexture(ID_WP_DepthNormalMap, null);
        Shader.SetGlobalVector(ID_WP_OutlineParams, new Vector4(0f, 0f, 0f, 1f));
    }

    private void Update()
    {
        UpdateAutoControl();

        UpdateDepthNormalMap();

        UpdateOutlineRender();
    }

    private void UpdateAutoControl()
    {
        if (autoControl)
        {
            // control by quality setting
            int lv = QualitySettings.GetQualityLevel();
            if (lv >= 3)
            {
                accuracy = 3;
            }
            else if (lv >= 2)
            {
                accuracy = 2;
            }
            else
            {
                ClearOutline();
            }
        }
    }

    private void UpdateDepthNormalMap()
    {
        int size = accuracy == 3 ? 2048 : (accuracy == 2 ? 1024 : 512);

        if (size == m_depthNormalMapSize)
            return;

        if (m_depthNormalMap)
            RenderTexture.ReleaseTemporary(m_depthNormalMap);

        m_depthNormalMapSize = size;
        m_depthNormalMap = RenderTexture.GetTemporary(size, size, 0, RenderTextureFormat.Default);
        m_depthNormalMap.filterMode = FilterMode.Point;
        depthNormal.targetTexture = m_depthNormalMap;
        Shader.SetGlobalTexture(ID_WP_DepthNormalMap, m_depthNormalMap);
    }

    private void UpdateOutlineRender()
    {
        depthNormal.aspect = m_mainCamera.aspect;
        depthNormal.fieldOfView = m_mainCamera.fieldOfView;
        depthNormal.orthographic = m_mainCamera.orthographic;
        depthNormal.orthographicSize = m_mainCamera.orthographicSize;
        depthNormal.nearClipPlane = m_mainCamera.nearClipPlane;
        depthNormal.farClipPlane = m_mainCamera.farClipPlane;
        depthNormal.cullingMask = cullingMask & m_mainCamera.cullingMask;

        Shader.SetGlobalVector(ID_WP_OutlineParams, new Vector4(outlineIntensity, outlinePower, 0, 1f));
        Shader.SetGlobalColor(ID_WP_OutlineColor, outlineColor);

        depthNormal.RenderWithShader(depthNormalMapShader, "RenderType");
    }

    public void FixShadowMapShader()
    {
        depthNormalMapShader = Shader.Find("WP/Outline/DepthNormal");
    }
}


#if UNITY_EDITOR
[CustomEditor(typeof(WPOutline), true)]
[CanEditMultipleObjects]
public class WPOutlineInspector : Editor
{
    WPOutline outline;

    SerializedProperty cullingMask;
    SerializedProperty accuracy;
    SerializedProperty outlineIntensity;
    SerializedProperty outlinePower;
    SerializedProperty outlineColor;
    SerializedProperty autoControl;
    SerializedProperty depthNormalMapShader;

    void OnEnable()
    {
        outline = target as WPOutline;

        cullingMask = serializedObject.FindProperty("cullingMask");
        accuracy = serializedObject.FindProperty("accuracy");
        outlineIntensity = serializedObject.FindProperty("outlineIntensity");
        outlinePower = serializedObject.FindProperty("outlinePower");
        outlineColor = serializedObject.FindProperty("outlineColor");
        autoControl = serializedObject.FindProperty("autoControl");
        depthNormalMapShader = serializedObject.FindProperty("depthNormalMapShader");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        EditorGUILayout.PropertyField(cullingMask);
        GUI.color = Color.white;
        EditorGUILayout.PropertyField(outlineIntensity);
        EditorGUILayout.PropertyField(outlinePower);
        EditorGUILayout.PropertyField(outlineColor);
        GUI.color = outline.autoControl ? Color.gray : Color.white;
        EditorGUILayout.PropertyField(accuracy);
        GUI.color = Color.white;
        EditorGUILayout.PropertyField(autoControl);
        EditorGUILayout.PropertyField(depthNormalMapShader);

        serializedObject.ApplyModifiedProperties();

        if (!outline.depthNormalMapShader)
        {
            EditorGUILayout.HelpBox("No depth normal shader selected.", MessageType.Warning);
        }
    }
}
#endif

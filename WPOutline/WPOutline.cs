using System;
using UnityEngine;
using UnityEngine.AI;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditorInternal;
#endif

public enum OutlineAnitAliasing
{
    None = 0,
    X2 = 1,
    X4 = 2,
    X8 = 3,
}

[Serializable]
public class WPOutlineSetting
{
    public LayerMask cullingMask;
    [Range(1, 3)]
    public int accuracy = 2;
    [Range(0f, 1f)]
    public float outlineIntensity = 0.5f;
    public OutlineAnitAliasing antiAliasing = OutlineAnitAliasing.None;
    [Range(0.5f, 10f)]
    public float antiAliasingSize = 2f;
}

[RequireComponent(typeof(Camera))]
public class WPOutline : MonoBehaviour
{
    public WPOutlineSetting highSetting = new WPOutlineSetting();
    public WPOutlineSetting midSetting = new WPOutlineSetting();
    public WPOutlineSetting lowSetting = new WPOutlineSetting();

    [Range(0.1f, 5f)]
    public float outlinePower = 0.5f;
    public Color outlineColor = Color.cyan;

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
            GameObject.Destroy(m_depthNormalCamera.gameObject);
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
        WPOutlineSetting setting = GetCurrentSetting();

        if (setting.cullingMask == 0 || setting.outlineIntensity <= 0.0001f)
        {
            ClearOutline();
            return;
        }

        UpdateDepthNormalMap(setting);

        UpdateOutlineRender(setting);
    }

    private WPOutlineSetting GetCurrentSetting()
    {
        int lv = QualitySettings.GetQualityLevel();
        if (lv >= 3)
            return highSetting;
        if (lv >= 2)
            return midSetting;
        return lowSetting;
    }

    private void UpdateDepthNormalMap(WPOutlineSetting setting)
    {
        int size = setting.accuracy == 3 ? 1024 : (setting.accuracy == 2 ? 512 : 256);

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

    private void UpdateOutlineRender(WPOutlineSetting setting)
    {
        depthNormal.aspect = m_mainCamera.aspect;
        depthNormal.fieldOfView = m_mainCamera.fieldOfView;
        depthNormal.orthographic = m_mainCamera.orthographic;
        depthNormal.orthographicSize = m_mainCamera.orthographicSize;
        depthNormal.nearClipPlane = m_mainCamera.nearClipPlane;
        depthNormal.farClipPlane = m_mainCamera.farClipPlane;
        depthNormal.cullingMask = setting.cullingMask & m_mainCamera.cullingMask;

        Shader.SetGlobalVector(ID_WP_OutlineParams, new Vector4(setting.outlineIntensity, (int)setting.antiAliasing, outlinePower, setting.antiAliasingSize));
        Shader.SetGlobalColor(ID_WP_OutlineColor, outlineColor);

        depthNormal.RenderWithShader(depthNormalMapShader, "RenderType");
    }

    public void FixShadowMapShader()
    {
        depthNormalMapShader = Shader.Find("WP/Outline/DepthNormal");
    }

    public void FixObjectShaderByLayer(int layer)
    {
        foreach (var mr in UnityEngine.Object.FindObjectsOfType<MeshRenderer>())
        {
            if (mr.gameObject.layer == layer)
            {
                if (mr.sharedMaterial)
                {
                    Shader shader = mr.sharedMaterial.shader;
                    if (shader)
                    {
                        switch (shader.name)
                        {
                            case "Mobile/Diffuse":
                                mr.sharedMaterial.shader = Shader.Find("WP/Outline/Diffuse");
                                break;
                        }
                    }
                }
            }
        }
    }
}


#if UNITY_EDITOR
[CustomEditor(typeof(WPOutline), true)]
[CanEditMultipleObjects]
public class WPOutlineInspector : Editor
{
    WPOutline outline;

    void OnEnable()
    {
        outline = target as WPOutline;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (!outline.depthNormalMapShader)
        {
            EditorGUILayout.HelpBox("No depth normal shader selected.", MessageType.Warning);
        }

        EditorGUILayout.Separator();
        GUI.color = Color.yellow;
        if (GUILayout.Button("EditorTest: Convert layer of default shaders"))
        {
            outline.FixObjectShaderByLayer(LayerMask.NameToLayer("Default"));
        }
    }
}
#endif

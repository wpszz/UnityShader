﻿using System;
using UnityEngine;
using UnityEngine.AI;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditorInternal;
#endif

public enum ShadowAnitAliasing
{
    None = 0,
    X2 = 1,
    X4 = 2,
    X8 = 3,
}

[Serializable]
public struct WPShadowSetting
{
    public LayerMask cullingMask;
    [Range(1, 3)]
    public int resolution;
    [Range(1f, 20f)]
    public float shadowDistance;
    [Range(0f, 1f)]
    public float shadowIntensity;
    public ShadowAnitAliasing antiAliasing;

    public static WPShadowSetting DefaultHighest
    {
        get
        {
            WPShadowSetting setting = new WPShadowSetting();
            setting.cullingMask = (1 << 8) | (1 << 9) | (1 << 15) | (1 << 17);  // Unit&Player&FightUnit&CutScene
            setting.resolution = 3;
            setting.shadowDistance = 20;
            setting.shadowIntensity = 0.5f;
            setting.antiAliasing = ShadowAnitAliasing.X4;
            return setting;
        }
    }

    public static WPShadowSetting DefaultHigh
    {
        get
        {
            WPShadowSetting setting = new WPShadowSetting();
            setting.cullingMask = (1 << 8) | (1 << 9) | (1 << 15) | (1 << 17);  // Unit&Player&FightUnit&CutScene
            setting.resolution = 3;
            setting.shadowDistance = 15;
            setting.shadowIntensity = 0.5f;
            setting.antiAliasing = ShadowAnitAliasing.X2;
            return setting;
        }
    }

    public static WPShadowSetting DefaultMid
    {
        get
        {
            WPShadowSetting setting = new WPShadowSetting();
            setting.cullingMask = (1 << 9);  // Player
            setting.resolution = 2;
            setting.shadowDistance = 10;
            setting.shadowIntensity = 0.5f;
            setting.antiAliasing = ShadowAnitAliasing.None;
            return setting;
        }
    }

    public static WPShadowSetting DefaultLow
    {
        get
        {
            WPShadowSetting setting = new WPShadowSetting();
            setting.cullingMask = 0;
            setting.resolution = 1;
            setting.shadowDistance = 10;
            setting.shadowIntensity = 0.5f;
            setting.antiAliasing = ShadowAnitAliasing.None;
            return setting;
        }
    }
}

[Serializable]
public struct WPShadowPlatform
{
    public WPShadowSetting highSetting;
    public WPShadowSetting midSetting;
    public WPShadowSetting lowSetting;

    public static WPShadowPlatform DefaultPC
    {
        get
        {
            WPShadowPlatform platform = new WPShadowPlatform();
            platform.highSetting = WPShadowSetting.DefaultHighest;
            platform.midSetting = WPShadowSetting.DefaultHigh;
            platform.lowSetting = WPShadowSetting.DefaultMid;
            return platform;
        }
    }

    public static WPShadowPlatform DefaultAndroid
    {
        get
        {
            WPShadowPlatform platform = new WPShadowPlatform();
            platform.highSetting = WPShadowSetting.DefaultHigh;
            platform.midSetting = WPShadowSetting.DefaultMid;
            platform.lowSetting = WPShadowSetting.DefaultLow;
            return platform;
        }
    }

    public static WPShadowPlatform DefaultIOS
    {
        get
        {
            WPShadowPlatform platform = new WPShadowPlatform();
            platform.highSetting = WPShadowSetting.DefaultHigh;
            platform.midSetting = WPShadowSetting.DefaultMid;
            platform.lowSetting = WPShadowSetting.DefaultLow;
            return platform;
        }
    }
}

public class WPShadow : MonoBehaviour
{
    public static int activeCullingMask
    {
        get;
        private set;
    }

    public WPShadowPlatform pcSetting = WPShadowPlatform.DefaultPC;
    public WPShadowPlatform androidSetting = WPShadowPlatform.DefaultAndroid;
    public WPShadowPlatform iosSetting = WPShadowPlatform.DefaultIOS;

    public Shader shadowMapShader;

    private Camera m_shadowCamera;
    private Camera shadowCamera
    {
        get
        {
            if (null == m_shadowCamera)
            {
                Transform node = new GameObject("Shadow Map Camera").transform;
                node.SetParent(transform);
                node.localPosition = Vector3.zero;
                node.localRotation = Quaternion.identity;
                node.localScale = Vector3.one;
                m_shadowCamera = node.gameObject.AddComponent<Camera>();
                m_shadowCamera.enabled = false;
                m_shadowCamera.clearFlags = CameraClearFlags.SolidColor;
                m_shadowCamera.backgroundColor = Color.white;
                m_shadowCamera.renderingPath = RenderingPath.VertexLit;
                m_shadowCamera.hdr = false;
                m_shadowCamera.useOcclusionCulling = false;
                m_shadowCamera.aspect = 1f;
                m_shadowCamera.orthographic = true;
            }
            return m_shadowCamera;
        }
    }

    Camera m_mainCamera;
    RenderTexture m_shadowMap;

    Transform m_transLight;
    Transform m_transShadowCamera;

    int m_shadowMapSize;

    Vector3[] m_frustumVertexs = new Vector3[8];

    Matrix4x4 m_correction4x4;

    private int ID_WP_ShadowMap;
    private int ID_WP_MatrixV;
    private int ID_WP_MatrixVPC;
    private int ID_WP_ControlParams;

    private RenderTextureFormat m_rtFormat = RenderTextureFormat.Default;

#if UNITY_EDITOR
    private void Awake()
    {
        if (!shadowMapShader || !shadowMapShader.isSupported)
            FixShadowMapShader();
    }
#endif

    private void Start()
    {
        ID_WP_ShadowMap = Shader.PropertyToID("WP_ShadowMap");
        ID_WP_MatrixV = Shader.PropertyToID("WP_MatrixV");
        ID_WP_MatrixVPC = Shader.PropertyToID("WP_MatrixVPC");
        ID_WP_ControlParams = Shader.PropertyToID("WP_ControlParams");

        m_transLight = this.transform;
        m_transShadowCamera = shadowCamera.transform;

        m_correction4x4 = new Matrix4x4();
        m_correction4x4.SetRow(0, new Vector4(0.5f, 0, 0, 0.5f));
        m_correction4x4.SetRow(1, new Vector4(0, 0.5f, 0, 0.5f));
        m_correction4x4.SetRow(2, new Vector4(0, 0, 1, 0));
        m_correction4x4.SetRow(3, new Vector4(0, 0, 0, 1));

        if (!shadowMapShader)
        {
            this.enabled = false;
            return;
        }

        if (SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.RGB565))
            m_rtFormat = RenderTextureFormat.RGB565;

        activeCullingMask = GetCurrentSetting().cullingMask;
    }

    private void OnDestroy()
    {
        ClearShadow();

        if (m_shadowCamera)
            GameObject.Destroy(m_shadowCamera.gameObject);
        m_shadowCamera = null;
    }

    private void OnDisable()
    {
        ClearShadow();
    }

    private void ClearShadow()
    {
        if (m_shadowMap)
            RenderTexture.ReleaseTemporary(m_shadowMap);
        m_shadowMap = null;
        m_shadowMapSize = 0;
        Shader.SetGlobalTexture(ID_WP_ShadowMap, null);
        Shader.SetGlobalVector(ID_WP_ControlParams, new Vector4(0f, 0f, 0f, 1f));
        activeCullingMask = 0;
    }

    private void Update()
    {
        WPShadowSetting setting = GetCurrentSetting();

        // Main camera maybe changed
        m_mainCamera = Camera.main;
        // Culling intersection with main camera
        activeCullingMask = setting.cullingMask & (m_mainCamera ? m_mainCamera.cullingMask : 0);

        if (activeCullingMask == 0 || setting.shadowIntensity <= 0.001f)
        {
            ClearShadow();
            return;
        }

        UpdateShadowDepthMap(setting);

        UpdateShadowMap(setting);
    }

    private WPShadowSetting GetCurrentSetting()
    {
        RuntimePlatform platform = Application.platform;
        WPShadowPlatform platformSetting = pcSetting;
        if (platform == RuntimePlatform.Android)
            platformSetting = androidSetting;
        else if (platform == RuntimePlatform.IPhonePlayer)
            platformSetting = iosSetting;

        int quality = QualitySettings.GetQualityLevel();
        if (quality >= 3)
            return platformSetting.highSetting;
        if (quality >= 2)
            return platformSetting.midSetting;
        return platformSetting.lowSetting;
    }

    private void UpdateShadowDepthMap(WPShadowSetting setting)
    {
        int size = setting.resolution == 3 ? 2048 : (setting.resolution == 2 ? 1024 : 512);

        if (size == m_shadowMapSize)
            return;

        if (m_shadowMap)
            RenderTexture.ReleaseTemporary(m_shadowMap);

        m_shadowMapSize = size;
        m_shadowMap = RenderTexture.GetTemporary(size, size, 0, m_rtFormat);
        m_shadowMap.filterMode = FilterMode.Point;
        shadowCamera.targetTexture = m_shadowMap;
        Shader.SetGlobalTexture(ID_WP_ShadowMap, m_shadowMap);
    }

    private void UpdateShadowMap(WPShadowSetting setting)
    {
        /*
         * 0      1
         *   near
         * 2      3
         */
        float nearDistance = m_mainCamera.nearClipPlane;
        float tanHalfFov = Mathf.Tan(m_mainCamera.fieldOfView * 0.5f * Mathf.Deg2Rad);
        float nearHalfHeight = tanHalfFov * nearDistance;
        float nearHalfWidth = nearHalfHeight * m_mainCamera.aspect;
        float farHalfHeight = tanHalfFov * setting.shadowDistance;
        float farHalfWidth = farHalfHeight * m_mainCamera.aspect;

        m_frustumVertexs[0] = new Vector3(-nearHalfWidth, nearHalfHeight, nearDistance);
        m_frustumVertexs[1] = new Vector3(nearHalfWidth, nearHalfHeight, nearDistance);
        m_frustumVertexs[2] = new Vector3(-nearHalfWidth, -nearHalfHeight, nearDistance);
        m_frustumVertexs[3] = new Vector3(nearHalfWidth, -nearHalfHeight, nearDistance);

        m_frustumVertexs[4] = new Vector3(-farHalfWidth, farHalfHeight, setting.shadowDistance);
        m_frustumVertexs[5] = new Vector3(farHalfWidth, farHalfHeight, setting.shadowDistance);
        m_frustumVertexs[6] = new Vector3(-farHalfWidth, -farHalfHeight, setting.shadowDistance);
        m_frustumVertexs[7] = new Vector3(farHalfWidth, -farHalfHeight, setting.shadowDistance);

        Matrix4x4 viewToWorld = m_mainCamera.transform.localToWorldMatrix;
        Matrix4x4 worldToLight = m_transLight.worldToLocalMatrix;
        Matrix4x4 VL = worldToLight * viewToWorld;
        for (int i = 0; i < 8; i++)
            m_frustumVertexs[i] = VL.MultiplyPoint(m_frustumVertexs[i]);

        float xMin = float.MaxValue, xMax = float.MinValue;
        float yMin = float.MaxValue, yMax = float.MinValue;
        float zMin = float.MaxValue, zMax = float.MinValue;
        for (int i = 0; i < 8; i++)
        {
            Vector3 v = m_frustumVertexs[i];
            xMin = Mathf.Min(xMin, v.x);
            xMax = Mathf.Max(xMax, v.x);
            yMin = Mathf.Min(yMin, v.y);
            yMax = Mathf.Max(yMax, v.y);
            zMin = Mathf.Min(zMin, v.z);
            zMax = Mathf.Max(zMax, v.z);
        }

        m_transShadowCamera.localPosition = new Vector3((xMin + xMax) * 0.5f, (yMin + yMax) * 0.5f, 0);
        shadowCamera.orthographicSize = Mathf.Max((xMax - xMin) * 0.5f, (yMax - yMin) * 0.5f);
        shadowCamera.nearClipPlane = zMin;
        shadowCamera.farClipPlane = zMax;
        shadowCamera.cullingMask = activeCullingMask;

        Matrix4x4 worldToView = shadowCamera.worldToCameraMatrix;
        Matrix4x4 projection = GL.GetGPUProjectionMatrix(shadowCamera.projectionMatrix, false);
        Matrix4x4 VPC = m_correction4x4 * projection * worldToView;
        Shader.SetGlobalMatrix(ID_WP_MatrixV, worldToView);
        Shader.SetGlobalMatrix(ID_WP_MatrixVPC, VPC);
        Shader.SetGlobalVector(ID_WP_ControlParams, new Vector4(setting.shadowIntensity, (int)setting.antiAliasing, zMin, 1f / (zMax - zMin)));

        shadowCamera.RenderWithShader(shadowMapShader, "RenderType");
    }

#if UNITY_EDITOR
    public void FixShadowMapShader()
    {
        shadowMapShader = Shader.Find("WP/Shadow/Depth");
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
                                mr.sharedMaterial.shader = Shader.Find("WP/Shadow/Diffuse");
                                break;
                            case "T4MShaders/ShaderModel2/MobileLM/T4M 2 Textures for Mobile":
                                mr.sharedMaterial.shader = Shader.Find("WP/Shadow/T4M 2 Textures for Mobile");
                                break;
                            case "T4MShaders/ShaderModel2/MobileLM/T4M 3 Textures for Mobile":
                                mr.sharedMaterial.shader = Shader.Find("WP/Shadow/T4M 3 Textures for Mobile");
                                break;
                            case "T4MShaders/ShaderModel2/MobileLM/T4M 4 Textures for Mobile":
                                mr.sharedMaterial.shader = Shader.Find("WP/Shadow/T4M 4 Textures for Mobile");
                                break;
                        }
                    }
                }
            }
        }
    }
#endif
}


#if UNITY_EDITOR
[CustomEditor(typeof(WPShadow), true)]
[CanEditMultipleObjects]
public class WPShadowInspector : Editor
{
    WPShadow shadow;

    void OnEnable()
    {
        shadow = target as WPShadow;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (!shadow.shadowMapShader)
        {
            EditorGUILayout.HelpBox("No shadow map shader selected.", MessageType.Warning);
        }

        EditorGUILayout.Separator();
        GUI.color = Color.yellow;
        if (GUILayout.Button("EditorTest: Convert layer of walkable shaders"))
        {
            shadow.FixObjectShaderByLayer(LayerMask.NameToLayer("Walkable"));
        }

        GUI.color = Color.white;
        RuntimePlatform platform = Application.platform;
        string platformName = "PC";
        if (platform == RuntimePlatform.Android)
            platformName = "Android";
        else if (platform == RuntimePlatform.IPhonePlayer)
            platformName = "IOS";
        int quality = QualitySettings.GetQualityLevel();
        string qualityName = "Low";
        if (quality >= 3)
            qualityName = "High";
        else if (quality >= 2)
            qualityName = "Mid";
        EditorGUILayout.HelpBox("Current setting: " + platformName + " " + qualityName, MessageType.Info);
    }
}
#endif

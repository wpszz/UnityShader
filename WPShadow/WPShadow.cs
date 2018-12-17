using System;
using UnityEngine;
using UnityEngine.AI;

#if UNITY_EDITOR
using UnityEditor;
using UnityEditorInternal;
#endif

[RequireComponent(typeof(Light))]
public class WPShadow : MonoBehaviour
{
    [Range(1, 3)]
    public int accuracy = 2;

    [Range(1f, 20f)]
    public float shadowDistance = 10f;

    public bool antiAliasing;

    public LayerMask cullingMask;
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
                m_shadowCamera.backgroundColor = new Color(0, 0, 0, 0);
                m_shadowCamera.renderingPath = RenderingPath.VertexLit;
                m_shadowCamera.hdr = false;
                m_shadowCamera.useOcclusionCulling = false;
                m_shadowCamera.aspect = 1f;
                m_shadowCamera.orthographic = true;
                m_shadowCamera.SetReplacementShader(shadowMapShader, "RenderType");
            }
            return m_shadowCamera;
        }
    }

    Camera m_mainCamera;
    RenderTexture m_shadowMap;

    Transform m_transMainCamera;
    Transform m_transLight;
    Transform m_transShadowCamera;

    int m_shadowMapSize;

    Vector3[] m_frustumVertexs = new Vector3[8];

    Matrix4x4 m_correction4x4;

    private void Start()
    {
        m_mainCamera = Camera.main;
        m_transMainCamera = m_mainCamera.transform;

        m_transLight = this.transform;
        m_transShadowCamera = shadowCamera.transform;

        m_correction4x4 = new Matrix4x4();
        m_correction4x4.SetRow(0, new Vector4(0.5f, 0, 0, 0.5f));
        m_correction4x4.SetRow(1, new Vector4(0, 0.5f, 0, 0.5f));
        m_correction4x4.SetRow(2, new Vector4(0, 0, 1, 0));
        m_correction4x4.SetRow(3, new Vector4(0, 0, 0, 1));

        if (!m_mainCamera || !shadowMapShader || !SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.Depth))
            this.enabled = false;
    }

    private void OnDestroy()
    {
        if (m_shadowMap)
            RenderTexture.ReleaseTemporary(m_shadowMap);
        m_shadowMap = null;
        Shader.SetGlobalTexture("WP_ShadowMap", null);
    }

    private void Update()
    {
        UpdateShadowDepthMap();

        UpdateShadowMap();
    }

    private void UpdateShadowDepthMap()
    {
        int size = accuracy == 3 ? 2048 : (accuracy == 2 ? 1024 : 512);

        if (size == m_shadowMapSize)
            return;

        if (m_shadowMap)
            RenderTexture.ReleaseTemporary(m_shadowMap);

        m_shadowMapSize = size;
        m_shadowMap = RenderTexture.GetTemporary(size, size, 16, RenderTextureFormat.Depth);
        shadowCamera.targetTexture = m_shadowMap;
        Shader.SetGlobalTexture("WP_ShadowMap", m_shadowMap);
    }

    private void UpdateShadowMap()
    {
        /*
         * 0      1
         *   near
         * 2      3
         */
        float nearDistance = m_mainCamera.nearClipPlane;
        float nearHalfHeight = Mathf.Tan(m_mainCamera.fieldOfView * 0.5f * Mathf.Deg2Rad) * nearDistance;
        float nearHalfWidth = nearHalfHeight * m_mainCamera.aspect;
        float farHalfHeight = Mathf.Tan(m_mainCamera.fieldOfView * 0.5f * Mathf.Deg2Rad) * shadowDistance;
        float farHalfWidth = farHalfHeight * m_mainCamera.aspect;

        m_frustumVertexs[0] = new Vector3(-nearHalfWidth, nearHalfHeight, nearDistance);
        m_frustumVertexs[1] = new Vector3(nearHalfWidth, nearHalfHeight, nearDistance);
        m_frustumVertexs[2] = new Vector3(-nearHalfWidth, -nearHalfHeight, nearDistance);
        m_frustumVertexs[3] = new Vector3(nearHalfWidth, -nearHalfHeight, nearDistance);

        m_frustumVertexs[4] = new Vector3(-farHalfWidth, farHalfHeight, shadowDistance);
        m_frustumVertexs[5] = new Vector3(farHalfWidth, farHalfHeight, shadowDistance);
        m_frustumVertexs[6] = new Vector3(-farHalfWidth, -farHalfHeight, shadowDistance);
        m_frustumVertexs[7] = new Vector3(farHalfWidth, -farHalfHeight, shadowDistance);

        Matrix4x4 viewToWorld = m_transMainCamera.localToWorldMatrix;
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
        shadowCamera.cullingMask = cullingMask;
        shadowCamera.Render();

        Matrix4x4 worldToView = shadowCamera.worldToCameraMatrix;
        Matrix4x4 projection = GL.GetGPUProjectionMatrix(shadowCamera.projectionMatrix, false);
        Matrix4x4 VPC = m_correction4x4 * projection * worldToView;
        Shader.SetGlobalMatrix("WP_MatrixV", worldToView);
        Shader.SetGlobalMatrix("WP_MatrixVPC", VPC);

        if (antiAliasing != Shader.IsKeywordEnabled("WP_SHADOW_AA"))
        {
            if (antiAliasing)
                Shader.EnableKeyword("WP_SHADOW_AA");
            else
                Shader.DisableKeyword("WP_SHADOW_AA");
        }
    }
}


#if UNITY_EDITOR
[CustomEditor(typeof(WPShadow), true)]
[CanEditMultipleObjects]
public class WPShadowInspector : Editor
{
    WPShadow shadow;

    SerializedProperty cullingMask;
    SerializedProperty accuracy;
    SerializedProperty shadowDistance;
    SerializedProperty antiAliasing;
    SerializedProperty shadowMapShader;

    void OnEnable()
    {
        shadow = target as WPShadow;

        cullingMask = serializedObject.FindProperty("cullingMask");
        accuracy = serializedObject.FindProperty("accuracy");
        shadowDistance = serializedObject.FindProperty("shadowDistance");
        antiAliasing = serializedObject.FindProperty("antiAliasing");
        shadowMapShader = serializedObject.FindProperty("shadowMapShader");
    }

    public override void OnInspectorGUI()
    {
        serializedObject.Update();

        EditorGUILayout.PropertyField(cullingMask);
        EditorGUILayout.PropertyField(accuracy);
        EditorGUILayout.PropertyField(shadowDistance);
        EditorGUILayout.PropertyField(antiAliasing);
        EditorGUILayout.PropertyField(shadowMapShader);

        serializedObject.ApplyModifiedProperties();

        if (!shadow.shadowMapShader)
        {
            EditorGUILayout.HelpBox("No shadow map shader selected.", MessageType.Warning);
        }
    }
}
#endif

using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
public class RayMarchBase : MonoBehaviour {

    [SerializeField]
    private Shader _rayMarchShader;


    [Header("Raymarch Settings")]
    [SerializeField]
    private bool _blendOnScene = true;

    [SerializeField, Min(1f)]
    private float _renderDistance = 100f;

    [SerializeField, Min(10)]
    private int _maxSteps = 100;

    [SerializeField, Min(0.0001f)]
    private float _surfDist = 0.01f;


    [Header("Light")]
    [SerializeField]
    private bool _usePointLight = false;

    [SerializeField]
    private Light _directionalLight;

    [SerializeField]
    private Light _pointLight;


    [Header("Shadows")]
    [SerializeField]
    private bool _useSoftShadows = true;

    [SerializeField, Range(0f, 20f)]
    private float _shadowsIntensity = 1f;

    [SerializeField]
    private Vector2 _shadowsDistance = new Vector2(0.05f, 100f);

    [SerializeField, Range(0f, 150f)]
    private float _shadowsSoftness = 4f;


    [Header("Ambient Occlusion")]
    [SerializeField, Range(0f, 2f)]
    private float _aoStep = 0.2f;

    [SerializeField, Range(0f, 1f)]
    private float _aoIntensity = 0.3f;

    [SerializeField, Range(0, 10)]
    private int _aoIterations = 3;


    [Header("Ambient Light")]
    [SerializeField]
    private bool _useUnityAmbient;
    [SerializeField]
    private Color _ambColor;


    private Material _renderMaterial;
    private RenderTexture _renderTexture;
    private Camera _currentCamera;

    // keywords
    LocalKeyword _useSoftShadowsKwd;
    LocalKeyword _blendOnSceneKwd;
    LocalKeyword _usePointLightKwd;
    LocalKeyword _useAmbMapKwd;

    private void Start() {
        if (_rayMarchShader == null) {
            _renderMaterial = null;
            return;
        } 
        
        _renderMaterial = new Material(_rayMarchShader);
        _currentCamera = GetComponent<Camera>();

        // keywords
        Shader shader = _renderMaterial.shader;
        _useSoftShadowsKwd = new LocalKeyword(shader, "RM_SOFT_SHADOWS_ON");
        _blendOnSceneKwd   = new LocalKeyword(shader, "RM_BLEND_ON_SCENE");
        _usePointLightKwd = new LocalKeyword(shader, "RM_POINT_LIGHT_ON");
        _useAmbMapKwd = new LocalKeyword(shader, "RM_AMB_MAP_ON");
    }

    //[ImageEffectOpaque]
    private void OnRenderImage(RenderTexture source, RenderTexture destination) {
        if (_renderMaterial == null) {
            Graphics.Blit(source, destination);
            return;
        }

        // camera values
        _renderMaterial.SetMatrix("_FrustumCornersMatrix", GetFrustumCorners(_currentCamera));
        _renderMaterial.SetMatrix("_CameraToWorldMatrix", _currentCamera.cameraToWorldMatrix);
        _renderMaterial.SetVector("_CameraWorldPos", _currentCamera.transform.position);

        // other values
        _renderMaterial.SetFloat("_MaxDist", _renderDistance);
        _renderMaterial.SetFloat("_SurfDist", _surfDist);
        _renderMaterial.SetInt("_MaxSteps", _maxSteps);
        _renderMaterial.SetVector("_DirLightDir", -_directionalLight.transform.forward);
        _renderMaterial.SetVector("_DirLightCol", _directionalLight.color);
        _renderMaterial.SetFloat("_DirLightInt", _directionalLight.intensity);
        _renderMaterial.SetVector("_PntLightPos", _pointLight.transform.position);
        _renderMaterial.SetVector("_PntLightCol", _pointLight.color);
        _renderMaterial.SetFloat("_PntLightInt", _pointLight.intensity);
        _renderMaterial.SetFloat("_ShadowsIntensity", _shadowsIntensity);
        _renderMaterial.SetFloat("_ShadowsSoftness", _shadowsSoftness);
        _renderMaterial.SetFloat("_ShadowsSoftness", _shadowsSoftness);
        _renderMaterial.SetVector("_ShadowsDistance", _shadowsDistance);
        _renderMaterial.SetFloat("_AoStep", _aoStep);
        _renderMaterial.SetFloat("_AoInt", _aoIntensity);
        _renderMaterial.SetFloat("_AoIterations", _aoIterations);
        _renderMaterial.SetVector("_AmbCol", _ambColor);

        // set keywords
        _renderMaterial.SetKeyword(_useSoftShadowsKwd, _useSoftShadows);
        _renderMaterial.SetKeyword(_blendOnSceneKwd, _blendOnScene);
        _renderMaterial.SetKeyword(_usePointLightKwd, _usePointLight);
        _renderMaterial.SetKeyword(_useAmbMapKwd, _useUnityAmbient);


        CustomGraphicsBlit(source, destination, _renderMaterial, 0);
    }

    private Matrix4x4 GetFrustumCorners(Camera cam) {
        float camFov = cam.fieldOfView;
        float camAspect = cam.aspect;

        Matrix4x4 frustumCorners = Matrix4x4.identity;

        float fovWHalf = camFov * 0.5f;

        float tan_fov = Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 toRight = Vector3.right * tan_fov * camAspect;
        Vector3 toTop = Vector3.up * tan_fov;

        Vector3 topLeft = (-Vector3.forward - toRight + toTop);
        Vector3 topRight = (-Vector3.forward + toRight + toTop);
        Vector3 bottomRight = (-Vector3.forward + toRight - toTop);
        Vector3 bottomLeft = (-Vector3.forward - toRight - toTop);

        frustumCorners.SetRow(0, topLeft);
        frustumCorners.SetRow(1, topRight);
        frustumCorners.SetRow(2, bottomRight);
        frustumCorners.SetRow(3, bottomLeft);

        return frustumCorners;
    }

    static void CustomGraphicsBlit(RenderTexture source, RenderTexture dest, Material fxMaterial, int passNr) {
        RenderTexture.active = dest;

        fxMaterial.SetTexture("_MainTex", source);

        GL.PushMatrix();
        GL.LoadOrtho(); // Note: z value of vertices don't make a difference because we are using ortho projection

        fxMaterial.SetPass(passNr);

        GL.Begin(GL.QUADS);

        // Here, GL.MultitexCoord2(0, x, y) assigns the value (x, y) to the TEXCOORD0 slot in the shader.
        // GL.Vertex3(x,y,z) queues up a vertex at position (x, y, z) to be drawn.  Note that we are storing
        // our own custom frustum information in the z coordinate.
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f); // BL

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f); // BR

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f); // TR

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f); // TL

        GL.End();
        GL.PopMatrix();
    }


}

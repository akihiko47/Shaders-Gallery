using UnityEngine;

public class ShellsGenerator : MonoBehaviour {

    [Header("Base For Material")]
    [SerializeField]
    private Mesh _shellMesh;

    [SerializeField]
    private Material _shellMaterial;


    [Header("Shells Settings")]
    [SerializeField, Range(0, 255)]
    private int _totalShells = 1;

    [SerializeField, Range(0f, 1f)]
    private float _shellsDistance = 0.1f;

    [SerializeField, Range(2, 1000)]
    private int _noiseDensity = 30;

    [SerializeField, Range(0f, 1000f)]
    private float _noiseScale = 30f;

    [SerializeField, Range(0f, 1f)]
    private float _randomCeof = 0.5f;

    [SerializeField, Range(0f, 10f)]
    private float _attenuation = 1.0f;


    [Header("Colors Settings")]
    [SerializeField]
    private Color _colorBase;

    [SerializeField]
    private Color _colorMiddle;

    [SerializeField]
    private Color _colorEdge;

    GameObject[] _shells;
    Material[] _materials;

    private void OnEnable() {
        CreateShells();
        SetShellsValues();
    }

    private void OnDisable() {
        DestroyShells();
    }

    private void Update() {
        if (_shells == null || _materials == null) {
            return;
        }

        if (_shells.Length != _totalShells) {
            DestroyShells();
            CreateShells();
        }
        SetShellsValues();
    }

    private void CreateShells() {
        _shells = new GameObject[_totalShells];
        _materials = new Material[_totalShells];

        for (int i = 0; i < _totalShells; i++) {
            GameObject shell = new GameObject("Shell" + i);
            shell.transform.parent = transform;
            shell.transform.localPosition = Vector3.zero;
            shell.transform.localScale = Vector3.one;
            shell.transform.localRotation = Quaternion.identity;

            _materials[i] = new Material(_shellMaterial);

            shell.AddComponent<MeshFilter>();
            shell.AddComponent<MeshRenderer>();
            shell.GetComponent<MeshFilter>().mesh = _shellMesh;
            shell.GetComponent<MeshRenderer>().material = _materials[i];

            _shells[i] = shell;
        }
    }

    private void DestroyShells() {
        if (_shells == null) {
            return;
        }

        for (int i = 0; i < _shells.Length; i++) {
            DestroyImmediate(_shells[i]);
        }
        _shells = null;

        for (int i = 0; i < _materials.Length; i++) {
            DestroyImmediate(_materials[i]);
        }
        _materials = null;
    }

    private void SetShellsValues() {
        if (_materials == null) {
            return;
        }

        for (int i = 0; i < _materials.Length; i++) {
            _materials[i].SetInt("_TotalShells", _totalShells);
            _materials[i].SetInt("_ShellIndex", i);
            _materials[i].SetFloat("_ShellsDistance", _shellsDistance);
            _materials[i].SetFloat("_NoiseDensity", _noiseDensity);
            _materials[i].SetColor("_ColBase", _colorBase);
            _materials[i].SetColor("_ColEdge", _colorEdge);
            _materials[i].SetColor("_ColMid", _colorMiddle);
            _materials[i].SetFloat("_NoiseScale", _noiseScale);
            _materials[i].SetFloat("_RandomCeof", _randomCeof);
            _materials[i].SetFloat("_Attenuation", _attenuation);
        }
    }

}

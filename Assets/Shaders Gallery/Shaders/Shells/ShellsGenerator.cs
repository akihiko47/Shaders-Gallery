using UnityEngine;

[ExecuteInEditMode]
public class ShellsGenerator : MonoBehaviour {

    [SerializeField]
    private Mesh _shellMesh;

    [SerializeField]
    private Material _shellMaterial;

    [SerializeField, Range(0, 255)]
    private int _totalShells = 1;

    [SerializeField, Range(0f, 1f)]
    private float _shellsDistance = 0.1f;

    GameObject[] _shells;

    private void OnEnable() {
        CreateShells();
    }

    private void OnDisable() {
        DestroyShells();
    }

    private void CreateShells() {
        _shells = new GameObject[_totalShells];

        for (int i = 0; i < _totalShells; i++) {
            GameObject shell = new GameObject("Shell" + i);
            shell.transform.parent = transform;
            shell.transform.localPosition = Vector3.zero;
            shell.transform.localScale = Vector3.one;
            shell.transform.localRotation = Quaternion.identity;

            shell.AddComponent<MeshFilter>();
            shell.AddComponent<MeshRenderer>();
            shell.GetComponent<MeshFilter>().mesh = _shellMesh;
            shell.GetComponent<MeshRenderer>().material = _shellMaterial;

            SetShellValues(i);

            _shells[i] = shell;
        }
    }

    private void DestroyShells() {
        for (int i = 0; i < _shells.Length; i++) {
            DestroyImmediate(_shells[i]);
        }
        _shells = null;
    }

    private void SetShellValues(int shellIndex) {
        Material mat = _shells[shellIndex].GetComponent<MeshRenderer>().material;

        mat.SetInt("_TotalShells", _totalShells);
        mat.SetFloat("_ShellsDistance", _shellsDistance);
        mat.SetInt("_ShellIndex", shellIndex);
    }

}

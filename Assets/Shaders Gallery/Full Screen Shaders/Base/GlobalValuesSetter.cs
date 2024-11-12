using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
[RequireComponent(typeof(Camera))]
public class GlobalValuesSetter : MonoBehaviour {

    private void OnRenderImage(RenderTexture source, RenderTexture destination) {

        // set global render texture for other effects
        RenderTexture renderTexture = RenderTexture.GetTemporary(source.width, source.height, 0, source.format);
        Graphics.Blit(source, renderTexture);
        Shader.SetGlobalTexture("_RenderTexture", renderTexture);
        RenderTexture.ReleaseTemporary(renderTexture);

        // set blured texture
        int width = source.width;
        int height = source.height;

        RenderTexture bluredTexture = RenderTexture.GetTemporary(width / 10, height / 10, 0, source.format);
        Graphics.Blit(source, bluredTexture);
        Shader.SetGlobalTexture("_BluredTexture", bluredTexture);
        RenderTexture.ReleaseTemporary(bluredTexture);

        Graphics.Blit(source, destination);
    }
}

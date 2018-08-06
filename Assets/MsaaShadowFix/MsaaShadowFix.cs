using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

namespace SH
{
    [ExecuteInEditMode]
    public class MsaaShadowFix : MonoBehaviour
    {
        private Light light;
        private CommandBuffer cmd;
        private Material mat;

        void OnEnable()
        {
            light = GetComponent<Light>();
            if( light == null && light.type != LightType.Directional)
            {
                Debug.LogWarning("No directional light found");
                enabled = false;
                return;
            }

            if( mat == null) {
                mat = new Material(Shader.Find("Hidden/SH/MsaaShadowFix"));
                mat.hideFlags = HideFlags.HideAndDontSave;
            }

            if( cmd == null) {
                cmd = new CommandBuffer();
                cmd.name = "ARome ShadowFilter";

                // fine on osx
                // cmd.SetGlobalTexture("_ARShadowCopy", BuiltinRenderTextureType.CurrentActive);
                cmd.Blit(BuiltinRenderTextureType.None, BuiltinRenderTextureType.CurrentActive, mat);

                // cmd.GetTemporaryRT(Shader.PropertyToID("_TmpShadows"), );
 
     			// int shadowCopy = Shader.PropertyToID("_ARShadowCopy");
			    // cmd.GetTemporaryRT (shadowCopy, -1, -1, 0, FilterMode.Bilinear);

                // cmd.CopyTexture(BuiltinRenderTextureType.CurrentActive, shadowCopy);
                // cmd.SetGlobalTexture("_ARShadowCopy", shadowCopy);
                // cmd.Blit(shadowCopy, BuiltinRenderTextureType.CurrentActive, mat);
                
                // cmd.SetGlobalTexture("_ARShadowCopy", BuiltinRenderTextureType.CurrentActive);
                light.AddCommandBuffer( LightEvent.AfterScreenspaceMask, cmd);
            }

            // Camera.onPreCull += ShadowsPreCull;
        }

        void OnDisable()
        {
            // Camera.onPreCull -= ShadowsPreCull;

            if ( cmd != null) {
                light.RemoveCommandBuffer( LightEvent.AfterScreenspaceMask, cmd);
                cmd = null;
            }

            if( mat != null) {
                DestroyImmediate(mat);
                mat = null;
            }
        }
    }
}
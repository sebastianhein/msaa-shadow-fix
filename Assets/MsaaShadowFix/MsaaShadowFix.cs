using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;

namespace SH
{
    [ExecuteInEditMode]
    public class MsaaShadowFix : MonoBehaviour
    {
        private Light dirLight;
        private CommandBuffer cmd;
        private Material mat;

        void OnEnable()
        {
            dirLight = GetComponent<Light>();
            if( dirLight == null && dirLight.type != LightType.Directional)
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

                cmd.Blit(BuiltinRenderTextureType.None, BuiltinRenderTextureType.CurrentActive, mat);
                dirLight.AddCommandBuffer( LightEvent.AfterScreenspaceMask, cmd);
            }
        }

        void OnDisable()
        {
            if ( cmd != null) {
                dirLight.RemoveCommandBuffer( LightEvent.AfterScreenspaceMask, cmd);
                cmd = null;
            }

            if( mat != null) {
                DestroyImmediate(mat);
                mat = null;
            }
        }
    }
}
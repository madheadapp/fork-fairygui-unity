using UnityEngine;
using UnityEngine.Events;

namespace FairyGUI
{
    [System.Serializable]
    public class PlayAudioEvent : UnityEvent<AudioClip, float>
    {
    }
}
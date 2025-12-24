using JetBrains.Annotations;
using UnityEngine;

namespace Terrain.Class.Data
{
    public static class GameplayViewSizeConfig
    {
        [UsedImplicitly] public const float GameplayContentMaxResolution = 18f / 9f;

        [UsedImplicitly] public const int GameplayContentMaxHeight =
            (int) (FairyGUIViewSizeConfig.ViewWidth * GameplayContentMaxResolution);

        public static int GameplayContentHeight => Mathf.Min( GameplayContentMaxHeight,
            FairyGUIViewSizeConfig.UIHeight - FairyGUIViewSizeConfig.TopBleedingHeight -
            FairyGUIViewSizeConfig.BottomBleedingHeight );

        public static float GameplayContentResolution => GameplayContentHeight / 640f;

        public static int GameplayExtraPadding => FairyGUIViewSizeConfig.UIHeight -
                                                  FairyGUIViewSizeConfig.TopBleedingHeight -
                                                  FairyGUIViewSizeConfig.BottomBleedingHeight - GameplayContentHeight;

        public static int GameplayTopBleeding => Mathf.FloorToInt(FairyGUIViewSizeConfig.TopBleedingHeight + GameplayExtraPadding / 2);
        public static int GameplayBottomBleeding => Mathf.CeilToInt(FairyGUIViewSizeConfig.BottomBleedingHeight + GameplayExtraPadding / 2);
    }
}
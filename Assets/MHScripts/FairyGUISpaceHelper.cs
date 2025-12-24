
using FairyGUI;
using UnityEngine;

namespace FairyGUICore
{
    public static class FairyGUISpaceHelper
    {
        public static Vector2 UnitySpaceToUISpace( Vector3 position )
        {
            var screenWidthInUISpace =
                FairyGUIViewSizeConfig.ViewWidth / FairyGUIViewSizeConfig.ViewScreenWidthRatio;
            var screenLeftRightPadding = screenWidthInUISpace * (1 - FairyGUIViewSizeConfig.ViewScreenWidthRatio) * 0.5f;

            var x = position.x / Screen.width * screenWidthInUISpace - screenLeftRightPadding;
            var y = position.y / Screen.height * FairyGUIViewSizeConfig.UIHeight -
                    FairyGUIViewSizeConfig.TopBleedingHeight;
            return new Vector2( x, y );
        }
        
        public static Vector2 UISpaceToUnitySpace( Vector2 position )
        {
            var screenWidthInUISpace =
                FairyGUIViewSizeConfig.ViewWidth / FairyGUIViewSizeConfig.ViewScreenWidthRatio;
            var screenLeftRightPadding = screenWidthInUISpace * (1 - FairyGUIViewSizeConfig.ViewScreenWidthRatio) * 0.5f;
            var viewHeightInUISpace = FairyGUIViewSizeConfig.ViewScreenHeight;

            var x = (position.x + screenLeftRightPadding) / screenWidthInUISpace * Screen.width;
            var y = (position.y - FairyGUIViewSizeConfig.ViewOffset + FairyGUIViewSizeConfig.TopBleedingHeight) *
                viewHeightInUISpace / FairyGUIViewSizeConfig.ViewHeight; // ;
            return new Vector2( x, y );
        }

        public static Vector3 UISpaceToLocal( this GObject gObject, Vector2 uiSpacePosition )
        {
            var unityPos = new Vector2( uiSpacePosition.x, -uiSpacePosition.y );
            var pt = gObject.displayObject.WorldToLocal( unityPos, Vector3.back );

            if ( gObject.pivotAsAnchor )
            {
                pt.x -= gObject.width * gObject.pivotX;
                pt.y -= gObject.height * gObject.pivotY;
            }

            return pt;
        }

        public static Vector3 LocalToUISpace( this GObject gObject, Vector2 localPosition )
        {
            var pt = localPosition;
            if ( gObject.pivotAsAnchor )
            {
                pt.x += gObject.width * gObject.pivotX;
                pt.y += gObject.height * gObject.pivotY;
            }

            var result = gObject.displayObject.TransformPoint( pt, null );
            result.y = -result.y;
            return result;
        }

        public static Vector2 ToScreenPosition( this GObject gObject )
        {
            if ( gObject.displayObject == null || gObject.displayObject.gameObject == null )
            {
                return Vector2.zero;
            }

            return UIPositionToScreenPosition( gObject.LocalToGlobal( Vector2.zero ) );
        }

        public static Vector2 UIPositionToScreenPosition( Vector2 position )
        {
            var inputEventPosition = FairyGUICore.FairyGUISpaceHelper.UISpaceToUnitySpace( position );
            return new Vector2( inputEventPosition.x, Screen.height - inputEventPosition.y );
        }

        public static Vector2 ScreenPositionToUIPosition( Vector3 position )
        {
            return FairyGUICore.FairyGUISpaceHelper.UnitySpaceToUISpace( new Vector3( position.x, Screen.height - position.y, position.z ) );
        }
    }
}
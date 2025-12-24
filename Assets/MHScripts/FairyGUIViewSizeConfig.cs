using JetBrains.Annotations;
using UnityEngine;

/**
 * For more information, please visit the notion documentation page.
 * https://www.notion.so/madheadapp/Dynamic-Safe-Area-8ca163871e004f5c9aad295d1435e6e8
 */
public static class FairyGUIViewSizeConfig
{
    [UsedImplicitly] public const float HeaderHeight = 140f;
    [UsedImplicitly] public const float FooterHeight = 104f;
    
    // The minimum height to maintain 9:16 aspect ratio, UI space
    [UsedImplicitly] public const int ViewMinHeight = 1136;

    // The maximum height, currently undefined, UI space
    [UsedImplicitly] public const int ViewMaxHeight = 9999;
    
    // Fixed width of UI space
    [UsedImplicitly] public const int ViewWidth = 640;

    // The extra padding to the bottom screen, UI space
    [UsedImplicitly] public const int ListBottomPadding = 200;
    
    // The distance required between touch up and down to cancel a click, UI Space
    [UsedImplicitly] public const int ClickCancelDistance = 50;
    
    // Old 9:16 TopBleedingHeight before Dynamic Safe Area, UI space
    [UsedImplicitly] public const float OldHeaderMargin = 46f;
    
    // Old 9:16 BottomBleedingHeight before Dynamic Safe Area, UI space
    [UsedImplicitly] public const float OldFooterMargin = 25f;
    
    // Old 9:16 Header Height before Dynamic Safe Area, UI space
    [UsedImplicitly] public const float OldHeaderHeight = 120f;
    
    // Old 9:16 Footer Height before Dynamic Safe Area, UI space
    [UsedImplicitly] public const float OldFooterHeight = 84f;

    // The maximum value of the top bleeding height, UI space
    [UsedImplicitly] public const int MaximumTopBleedingHeight = 120;
    
    // The maximum value of the bottom bleeding height, UI space
    [UsedImplicitly] public const int MaximumBottomBleedingHeight = 120;

    // The safe area in unity safe area space
    private static Rect _safeArea;

    // The difference between the new and old top bleeding and header height, UI space
    public static float HeaderMarginOffset => TopBleedingHeight - OldHeaderMargin + HeaderHeight - OldHeaderHeight;
    
    // The difference between the new and old bottom bleeding and footer height, UI space
    public static float FooterMarginOffset => BottomBleedingHeight - OldFooterMargin + FooterHeight - OldFooterHeight;
    
    // The height inside the safe area, UI space
    public static int ViewHeight { get; private set; }
    
    // The height of the top unsafe area but inside the ui area, UI space
    public static int TopBleedingHeight { get; private set; }
    
    // The height of the bottom unsafe area but inside the ui area, UI space
    public static int BottomBleedingHeight { get; private set; }
    
    // The height adjustment required for the camera to point to point to the correct position, UI space
    // Please visit the documentation page for more information
    public static int ViewOffset { get; private set; }
    
    // The aspect ratio of the UI area
    public static float ViewAspectRatio => ViewWidth * 1f / ViewHeight;
    
    // The aspect ratio of the screen, Screen Space
    public static float ScreenAspectRatio => 1f * Screen.width / Screen.height;
    
    // The width of the UI, screen space
    public static float ViewScreenWidth => 1f * ViewWidth * Screen.height / UIHeight;
    
    // The height of the ui area, UI space
    public static int UIHeight => ViewHeight + TopBleedingHeight + BottomBleedingHeight;
    
    // The ratio of screen width to ui width
    public static float ViewScreenWidthRatio => ViewScreenWidth * 1f / Screen.width;
    
    // The height of the safe area, screen space
    public static int ViewScreenHeight => Mathf.CeilToInt( ViewHeight * ViewScreenWidth * 1f / ViewWidth );
    
    // The ratio of screen height to ui height
    public static float ViewScreenHeightRatio => ViewScreenHeight * 1f / Screen.height;
    
    // The ratio of ui space height to screen height
    public static float ScreenToUISpaceMultiplier => UIHeight * 1f / Screen.height;
    
    // For legacy support of the old ui
    public static float OldCameraRatio { get; set; } = 1f;
    
    // The distance required between touch up and down to cancel a click, screen Space
    public static float UISpaceClickCancelDistance => ClickCancelDistance * 1f / Screen.height * UIHeight;

    // The Rect for screenshot purpose, unity safe area space
    public static Rect ScreenshotRect
    {
        get
        {
            var x = ( 1 - ViewScreenWidthRatio ) / 2 * Screen.width;
            var y = _safeArea.y;
            var width = ViewScreenWidth;
            var height = ViewScreenHeight;

            return new Rect( x , y , width , height );
        }
    }
    
    public static void UpdateViewSizeConfig()
    {
        // Obtain safe area from unity
        // Safe Area has origin in bottom left corner of the screen
        _safeArea = Screen.safeArea;
        
        // Clamp the safe area within the maximum unsafe area height
        // Do not clamp if the device is smaller than 16:9
        if ( (float)Screen.height / Screen.width >= (float)ViewMinHeight / ViewWidth )
        {
            
            var maximumTopBleedingScreenHeight = (float) MaximumTopBleedingHeight / ViewWidth * Screen.width;
            var maximumBottomBleedingScreenHeight = (float) MaximumBottomBleedingHeight / ViewWidth * Screen.width;

            // Clamp bottom
            if ( _safeArea.y > maximumBottomBleedingScreenHeight )
            {
                var bottomOffset = _safeArea.y - maximumBottomBleedingScreenHeight;
                _safeArea.y -= bottomOffset;
                _safeArea.height += bottomOffset;
            }

            // Clamp top
            if ( Screen.height - _safeArea.y - _safeArea.height > maximumTopBleedingScreenHeight )
            {
                var topBleedingScreenHeight = Screen.height - _safeArea.y - _safeArea.height;
                var topOffset = topBleedingScreenHeight - maximumTopBleedingScreenHeight;
                _safeArea.height += topOffset;
            }
        }

        // Height of bleeding bottom, screen space
        // For devices with aspect ratio < 16:9 (such as iPad), calculate the height differently
        // For iPads, ignore the safe area due to the complexity of calculating the camera view port
        // and the compatibility with the gameplay view
        var bottomBorderHeight = (float) Screen.height / Screen.width < (float) ViewMinHeight / ViewWidth ? 0f : _safeArea.y;
        
        // Height of safe area, ui space
        var safeAreaHeight =  ViewWidth * (Screen.height < _safeArea.height ? Screen.height : _safeArea.height) / Screen.width;
        // Full height, ui space
        var actualHeight = (float) ViewWidth * Screen.height / Screen.width;

        // UI space height
        ViewHeight = Mathf.CeilToInt(Mathf.Clamp( Mathf.Min(actualHeight, safeAreaHeight) , ViewMinHeight , ViewMaxHeight ));

        // Height of bleeding top, screen space
        var topBorderHeight = Screen.height - _safeArea.y - _safeArea.height;
        
        // Difference between bleeding top and bleeding bottom, UI space
        var viewOffset = safeAreaHeight < ViewMaxHeight
            ? 1f * (topBorderHeight - bottomBorderHeight) * ViewWidth / Screen.width : 0;
        
        // Calculate bottom bleeding in the most fancy way possible to avoid negative values
        var paddingSize = Mathf.CeilToInt( Mathf.Max( 0 , ( actualHeight - ViewHeight - viewOffset ) / 2 ) );
        BottomBleedingHeight = paddingSize;
        
        // Calculate top bleeding in the most questionable way possible
        TopBleedingHeight = Mathf.CeilToInt( paddingSize + viewOffset );
        
        // The camera only needs to move half the distance to achieve the view offset
        ViewOffset = Mathf.CeilToInt( viewOffset / 2 );
    }
}
package com.ntp.ntitamagochi

import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var nativeSplashOverlay: View? = null
    private var flutterUiDisplayed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!flutterUiDisplayed) {
            nativeSplashOverlay = View(this).apply {
                setBackgroundResource(R.drawable.launch_background)
                isClickable = true
                isFocusable = true
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }

            addContentView(
                nativeSplashOverlay,
                ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.MATCH_PARENT,
                ),
            )
        }
    }

    override fun onFlutterUiDisplayed() {
        super.onFlutterUiDisplayed()
        flutterUiDisplayed = true
        removeNativeSplashOverlay()
    }

    override fun onDestroy() {
        removeNativeSplashOverlay()
        super.onDestroy()
    }

    private fun removeNativeSplashOverlay() {
        val overlay = nativeSplashOverlay ?: return
        (overlay.parent as? ViewGroup)?.removeView(overlay)
        nativeSplashOverlay = null
    }
}

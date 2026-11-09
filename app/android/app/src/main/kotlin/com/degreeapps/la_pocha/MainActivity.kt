package com.degreeapps.la_pocha

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterActivity extends android.app.Activity (not ComponentActivity), so
// androidx.activity.enableEdgeToEdge() cannot be called on it. FlutterFragmentActivity
// extends FragmentActivity → ComponentActivity and supports enableEdgeToEdge().
class MainActivity : FlutterFragmentActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    enableEdgeToEdge()
    super.onCreate(savedInstanceState)
  }
}

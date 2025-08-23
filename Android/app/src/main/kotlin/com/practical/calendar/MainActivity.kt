package com.practical.calendar

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.activity.viewModels
import com.practical.calendar.ui.screen.MainScreen
import com.practical.calendar.ui.theme.PractiCalTheme
import com.practical.calendar.ui.viewmodel.CalendarViewModel
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    private val calendarViewModel: CalendarViewModel by viewModels()

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        val calendarReadGranted = permissions[Manifest.permission.READ_CALENDAR] == true
        val calendarWriteGranted = permissions[Manifest.permission.WRITE_CALENDAR] == true

        if (calendarReadGranted && calendarWriteGranted) {
            // Permissions granted, notify ViewModel to load data
            calendarViewModel.onPermissionsGranted()
        } else {
            // Permissions denied, notify ViewModel
            calendarViewModel.onPermissionsDenied()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check and request calendar permissions
        checkAndRequestCalendarPermissions()

        setContent {
            PractiCalTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainScreen()
                }
            }
        }
    }

    private fun checkAndRequestCalendarPermissions() {
        val readPermission = ContextCompat.checkSelfPermission(
            this, Manifest.permission.READ_CALENDAR
        )
        val writePermission = ContextCompat.checkSelfPermission(
            this, Manifest.permission.WRITE_CALENDAR
        )

        if (readPermission.isGranted() && writePermission.isGranted()) {
            // Permissions already granted, notify ViewModel immediately
            calendarViewModel.onPermissionsGranted()
        } else {
            // Need to request permissions
            permissionLauncher.launch(
                arrayOf(
                    Manifest.permission.READ_CALENDAR,
                    Manifest.permission.WRITE_CALENDAR
                )
            )
        }
    }

}

// Extension function to check if a permission is granted
private fun Int.isGranted(): Boolean = this == PackageManager.PERMISSION_GRANTED

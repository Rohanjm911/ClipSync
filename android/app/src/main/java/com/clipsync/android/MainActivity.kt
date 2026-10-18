package com.clipsync.android

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.clipsync.android.model.ClipboardItem
import com.clipsync.android.model.ConnectionState
import com.clipsync.android.model.PairedDevice
import com.clipsync.android.service.ClipboardSyncService
import com.clipsync.android.ui.theme.*

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Start Foreground Service for clipboard monitoring
        startForegroundService(Intent(this, ClipboardSyncService::class.java))

        setContent {
            ClipSyncTheme {
                MainAppScreen()
            }
        }
    }
}

enum class MobileTab {
    DASHBOARD,
    PAIRING,
    DEVICES,
    HISTORY,
    SETTINGS
}

@Composable
fun MainAppScreen() {
    var currentTab by remember { mutableStateOf(MobileTab.DASHBOARD) }
    var connectionState by remember { mutableStateOf(ConnectionState.CONNECTED_DIRECT) }
    var deviceName by remember { mutableStateOf("Android-Pixel-84F2") }

    val mockPeers = remember {
        mutableStateListOf(
            PairedDevice(
                deviceId = "dev_win_desktop_9A2E",
                deviceName = "Desktop-Win-9A2E",
                ed25519PubKey = "ed_pub_win_001",
                x25519PubKey = "x_pub_win_001",
                pairedAt = System.currentTimeMillis() - 7200000,
                lastSeen = System.currentTimeMillis() - 15000,
                isOnline = true,
                connectionMode = "LOCAL_WIFI"
            )
        )
    }

    val historyItems = remember {
        mutableStateListOf(
            ClipboardItem(
                id = "clip_1",
                contentType = "text/plain",
                textData = "https://github.com/clipsync/clipsync",
                contentHash = "hash_001",
                originDeviceId = "dev_win_desktop_9A2E",
                timestamp = System.currentTimeMillis() - 60000,
                isPinned = false,
                isSensitive = false
            ),
            ClipboardItem(
                id = "clip_2",
                contentType = "text/plain",
                textData = "Meeting notes: Review ClipSync security audit",
                contentHash = "hash_002",
                originDeviceId = "dev_android_84F2",
                timestamp = System.currentTimeMillis() - 180000,
                isPinned = false,
                isSensitive = false
            )
        )
    }

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = SolidSurfaceDark,
                contentColor = Color.White
            ) {
                NavigationBarItem(
                    selected = currentTab == MobileTab.DASHBOARD,
                    onClick = { currentTab = MobileTab.DASHBOARD },
                    label = { Text("Dashboard", fontSize = 11.sp) },
                    icon = { Text("📋", fontSize = 16.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SolidPrimary,
                        selectedTextColor = SolidPrimary,
                        indicatorColor = SolidSurfaceElevated
                    )
                )
                NavigationBarItem(
                    selected = currentTab == MobileTab.PAIRING,
                    onClick = { currentTab = MobileTab.PAIRING },
                    label = { Text("Pairing", fontSize = 11.sp) },
                    icon = { Text("📷", fontSize = 16.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SolidPrimary,
                        selectedTextColor = SolidPrimary,
                        indicatorColor = SolidSurfaceElevated
                    )
                )
                NavigationBarItem(
                    selected = currentTab == MobileTab.DEVICES,
                    onClick = { currentTab = MobileTab.DEVICES },
                    label = { Text("Devices", fontSize = 11.sp) },
                    icon = { Text("💻", fontSize = 16.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SolidPrimary,
                        selectedTextColor = SolidPrimary,
                        indicatorColor = SolidSurfaceElevated
                    )
                )
                NavigationBarItem(
                    selected = currentTab == MobileTab.HISTORY,
                    onClick = { currentTab = MobileTab.HISTORY },
                    label = { Text("History", fontSize = 11.sp) },
                    icon = { Text("🕒", fontSize = 16.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SolidPrimary,
                        selectedTextColor = SolidPrimary,
                        indicatorColor = SolidSurfaceElevated
                    )
                )
                NavigationBarItem(
                    selected = currentTab == MobileTab.SETTINGS,
                    onClick = { currentTab = MobileTab.SETTINGS },
                    label = { Text("Settings", fontSize = 11.sp) },
                    icon = { Text("⚙️", fontSize = 16.sp) },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = SolidPrimary,
                        selectedTextColor = SolidPrimary,
                        indicatorColor = SolidSurfaceElevated
                    )
                )
            }
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(SolidBlack)
                .padding(padding)
        ) {
            when (currentTab) {
                MobileTab.DASHBOARD -> DashboardScreen(deviceName, connectionState, historyItems)
                MobileTab.PAIRING -> PairingScreen(onPairSuccess = { peer -> mockPeers.add(peer) })
                MobileTab.DEVICES -> DevicesScreen(mockPeers, onRevoke = { dev -> mockPeers.remove(dev) })
                MobileTab.HISTORY -> HistoryScreen(historyItems, onClear = { historyItems.clear() })
                MobileTab.SETTINGS -> SettingsScreen()
            }
        }
    }
}

@Composable
fun DashboardScreen(
    deviceName: String,
    state: ConnectionState,
    history: List<ClipboardItem>
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(20.dp)
    ) {
        Text(
            text = "ClipSync",
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White
        )
        Text(
            text = "Copy Anywhere. Paste Everywhere.",
            fontSize = 13.sp,
            color = TextSecondaryDark,
            modifier = Modifier.padding(top = 2.dp, bottom = 20.dp)
        )

        // Status Card (Strict Solid Colors)
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, SolidBorderDark, RoundedCornerShape(8.dp)),
            colors = CardDefaults.cardColors(containerColor = SolidSurfaceDark),
            shape = RoundedCornerShape(8.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = deviceName,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White,
                        fontSize = 15.sp
                    )
                    Box(
                        modifier = Modifier
                            .background(SolidSuccess, RoundedCornerShape(4.dp))
                            .padding(horizontal = 8.dp, vertical = 3.dp)
                    ) {
                        Text(
                            text = "CONNECTED",
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Active Transport: Direct Local Wi-Fi (12ms RTT)",
                    fontSize = 12.sp,
                    color = TextSecondaryDark
                )
                Text(
                    text = "End-to-End Encryption: ChaCha20-Poly1305 / Ed25519",
                    fontSize = 12.sp,
                    color = TextSecondaryDark,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        Text(
            text = "Latest Synchronized Clip",
            fontSize = 14.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White,
            modifier = Modifier.padding(bottom = 8.dp)
        )

        val latest = history.firstOrNull()
        if (latest != null) {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, SolidBorderDark, RoundedCornerShape(8.dp)),
                colors = CardDefaults.cardColors(containerColor = SolidSurfaceDark),
                shape = RoundedCornerShape(8.dp)
            ) {
                Column(modifier = Modifier.padding(14.dp)) {
                    Text(
                        text = latest.textData,
                        fontFamily = FontFamily.Monospace,
                        fontSize = 13.sp,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Origin: ${latest.originDeviceId} • ${latest.contentType}",
                        fontSize = 11.sp,
                        color = TextSecondaryDark
                    )
                }
            }
        } else {
            Text(
                text = "No clipboard events yet.",
                fontSize = 13.sp,
                color = TextSecondaryDark
            )
        }
    }
}

@Composable
fun PairingScreen(onPairSuccess: (PairedDevice) -> Unit) {
    var codeInput by remember { mutableStateOf("") }
    var peerNameInput by remember { mutableStateOf("") }
    var isPaired by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(20.dp)
    ) {
        Text(
            text = "Pair with Windows Desktop",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White
        )
        Text(
            text = "Scan QR code on your Windows screen or enter 6-digit confirmation code",
            fontSize = 13.sp,
            color = TextSecondaryDark,
            modifier = Modifier.padding(top = 2.dp, bottom = 20.dp)
        )

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, SolidBorderDark, RoundedCornerShape(8.dp)),
            colors = CardDefaults.cardColors(containerColor = SolidSurfaceDark),
            shape = RoundedCornerShape(8.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                OutlinedTextField(
                    value = peerNameInput,
                    onValueChange = { peerNameInput = it },
                    label = { Text("Desktop Friendly Name") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = SolidPrimary,
                        unfocusedBorderColor = SolidBorderDark
                    )
                )

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = codeInput,
                    onValueChange = { codeInput = it },
                    label = { Text("6-Digit Confirmation Code") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = SolidPrimary,
                        unfocusedBorderColor = SolidBorderDark
                    )
                )

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = {
                        if (codeInput.length == 6) {
                            val newPeer = PairedDevice(
                                deviceId = "dev_win_" + codeInput,
                                deviceName = if (peerNameInput.isBlank()) "Windows Desktop" else peerNameInput,
                                ed25519PubKey = "ed_win_key",
                                x25519PubKey = "x_win_key",
                                pairedAt = System.currentTimeMillis(),
                                lastSeen = System.currentTimeMillis(),
                                isOnline = true
                            )
                            onPairSuccess(newPeer)
                            isPaired = true
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = SolidPrimary),
                    shape = RoundedCornerShape(6.dp)
                ) {
                    Text("Approve Pairing & Exchange Keys", fontWeight = FontWeight.SemiBold)
                }

                if (isPaired) {
                    Text(
                        text = "Device paired successfully!",
                        color = SolidSuccess,
                        fontSize = 13.sp,
                        modifier = Modifier.padding(top = 10.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun DevicesScreen(peers: List<PairedDevice>, onRevoke: (PairedDevice) -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(20.dp)
    ) {
        Text(
            text = "Paired Devices",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White
        )
        Text(
            text = "Authorized computers and phones in your clipboard sync ring",
            fontSize = 13.sp,
            color = TextSecondaryDark,
            modifier = Modifier.padding(top = 2.dp, bottom = 20.dp)
        )

        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(peers) { peer ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, SolidBorderDark, RoundedCornerShape(8.dp)),
                    colors = CardDefaults.cardColors(containerColor = SolidSurfaceDark),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(14.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column {
                            Text(text = peer.deviceName, fontWeight = FontWeight.SemiBold, color = Color.White)
                            Text(
                                text = "Fingerprint: ${peer.deviceId.take(16)}...",
                                fontSize = 11.sp,
                                fontFamily = FontFamily.Monospace,
                                color = TextSecondaryDark
                            )
                        }
                        Button(
                            onClick = { onRevoke(peer) },
                            colors = ButtonDefaults.buttonColors(containerColor = SolidError),
                            shape = RoundedCornerShape(4.dp)
                        ) {
                            Text("Revoke", fontSize = 12.sp)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun HistoryScreen(history: List<ClipboardItem>, onClear: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(20.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(text = "Clipboard History", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.White)
                Text(text = "Locally encrypted archive", fontSize = 13.sp, color = TextSecondaryDark)
            }
            Button(
                onClick = onClear,
                colors = ButtonDefaults.buttonColors(containerColor = SolidSurfaceElevated),
                shape = RoundedCornerShape(4.dp)
            ) {
                Text("Clear", color = Color.White, fontSize = 12.sp)
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        LazyColumn(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            items(history) { item ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .border(1.dp, SolidBorderDark, RoundedCornerShape(8.dp)),
                    colors = CardDefaults.cardColors(containerColor = SolidSurfaceDark),
                    shape = RoundedCornerShape(8.dp)
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Text(
                            text = item.textData,
                            fontFamily = FontFamily.Monospace,
                            fontSize = 13.sp,
                            color = Color.White
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = item.contentType,
                            fontSize = 11.sp,
                            color = SolidPrimary
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun SettingsScreen() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(20.dp)
    ) {
        Text(text = "Settings", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color.White)
        Text(text = "Network mode and security preferences", fontSize = 13.sp, color = TextSecondaryDark, modifier = Modifier.padding(bottom = 20.dp))

        Card(
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, SolidBorderDark, RoundedCornerShape(8.dp)),
            colors = CardDefaults.cardColors(containerColor = SolidSurfaceDark),
            shape = RoundedCornerShape(8.dp)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Text(text = "Network Mode: Smart Hybrid", fontWeight = FontWeight.SemiBold, color = Color.White, fontSize = 14.sp)
                Text(text = "Prefers direct local Wi-Fi; uses WebRTC P2P when outside home network.", fontSize = 12.sp, color = TextSecondaryDark, modifier = Modifier.padding(top = 2.dp, bottom = 14.dp))

                Divider(color = SolidBorderDark)

                Spacer(modifier = Modifier.height(14.dp))
                Text(text = "Privacy: Secret Filtering Active", fontWeight = FontWeight.SemiBold, color = Color.White, fontSize = 14.sp)
                Text(text = "Private keys, passwords, and credit cards are automatically excluded from sync.", fontSize = 12.sp, color = TextSecondaryDark, modifier = Modifier.padding(top = 2.dp))
            }
        }
    }
}

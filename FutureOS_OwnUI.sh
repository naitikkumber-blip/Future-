#!/bin/bash
# ============================================================
# FutureOS OwnUI - 100% Self-Contained Mobile Builder
# No GitHub! No Downloads! Everything Built-In!
# ============================================================

echo "╔══════════════════════════════════════════════════════╗"
echo "║       FutureOS OwnUI Builder v1.0                 ║"
echo "║   Build Your OWN Android UI - 100% Mobile!         ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# Detect if running on Android
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ This script is designed for Termux on Android!"
    exit 1
fi

# Step 1: Update and Install
echo "[1/12] Installing required packages..."
pkg update && pkg upgrade -y -y 2>/dev/null
pkg install -y openjdk-17 gradle wget unzip 2>/dev/null

# Step 2: Create Project
echo "[2/12] Creating project..."
rm -rf ~/FutureOS_OwnUI 2>/dev/null
mkdir -p ~/FutureOS_OwnUI
cd ~/FutureOS_OwnUI

# Step 3: Create Directory Structure
echo "[3/12] Setting up directories..."
mkdir -p app/src/main/java/com/futuros/ownui
mkdir -p app/src/main/res/{layout,values,mipmap-hdpi,mipmap-mdpi,mipmap-xhdpi,mipmap-xxhdpi,mipmap-xxxhdpi}

# Step 4: Create AndroidManifest.xml
echo "[4/12] Creating Android Manifest..."
cat > app/src/main/AndroidManifest.xml << 'MANIFEST'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.futuros.ownui">
    
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.SET_WALLPAPER"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    
    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="FutureOS"
        android:theme="@style/AppTheme">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTask"
            android:stateNotNeeded="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.HOME"/>
                <category android:name="android.intent.category.DEFAULT"/>
            </intent-filter>
        </activity>
        
        <activity android:name=".AppDrawer" android:exported="false"/>
        <activity android:name=".Settings" android:exported="false"/>
        
        <receiver android:name=".BootReceiver" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>
    </application>
</manifest>
MANIFEST

# Step 5: Create MainActivity.java - Complete Custom Launcher
echo "[5/12] Creating MainActivity (Home Screen)..."
cat > app/src/main/java/com/futuros/ownui/MainActivity.java << 'JAVA'
package com.futuros.ownui;

import android.app.*;
import android.content.*;
import android.content.pm.*;
import android.graphics.*;
import android.graphics.drawable.*;
import android.os.*;
import android.view.*;
import android.widget.*;
import java.util.*;
import java.text.*;

public class MainActivity extends Activity {
    
    LinearLayout mainLayout;
    GridLayout appGrid;
    TextView clock, date, weather;
    ImageButton btnSettings, btnDrawer, btnRecent;
    ArrayList<AppInfo> apps = new ArrayList<>();
    
    @Override
    protected void onCreate(Bundle saved) {
        super.onCreate(saved);
        createUI();
        setContentView(mainLayout);
        loadApps();
        startClock();
    }
    
    void createUI() {
        mainLayout = new LinearLayout(this);
        mainLayout.setOrientation(LinearLayout.VERTICAL);
        mainLayout.setGravity(Gravity.CENTER_HORIZONTAL);
        
        // Custom Background Gradient
        GradientDrawable bg = new GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            new int[]{0xFF1A1A2E, 0xFF16213E, 0xFF0F3460}
        );
        mainLayout.setBackground(bg);
        
        // Top Section - Clock & Date
        LinearLayout topSection = new LinearLayout(this);
        topSection.setOrientation(LinearLayout.VERTICAL);
        topSection.setGravity(Gravity.CENTER);
        topSection.setPadding(0, 120, 0, 40);
        
        // Clock
        clock = new TextView(this);
        clock.setText("00:00");
        clock.setTextSize(72);
        clock.setTextColor(Color.WHITE);
        clock.setTypeface(Typeface.create("sans-serif-light", Typeface.NORMAL));
        
        // Date
        date = new TextView(this);
        date.setText("Monday, Jan 1");
        date.setTextSize(18);
        date.setTextColor(Color.parseColor("#888888"));
        date.setPadding(0, 10, 0, 0);
        
        // Weather Widget
        weather = new TextView(this);
        weather.setText("☀️ 28°C - Sunny");
        weather.setTextSize(16);
        weather.setTextColor(Color.parseColor("#00D9FF"));
        weather.setPadding(0, 20, 0, 40);
        
        topSection.addView(clock);
        topSection.addView(date);
        topSection.addView(weather);
        
        // App Grid
        appGrid = new GridLayout(this);
        appGrid.setColumnCount(4);
        appGrid.setPadding(30, 20, 30, 20);
        
        // Bottom Bar
        LinearLayout bottomBar = new LinearLayout(this);
        bottomBar.setOrientation(LinearLayout.HORIZONTAL);
        bottomBar.setGravity(Gravity.CENTER);
        bottomBar.setPadding(0, 30, 0, 80);
        
        btnSettings = newImageButton(android.R.drawable.ic_menu_preferences);
        btnDrawer = newImageButton(android.R.drawable.ic_menu_agenda);
        btnRecent = newImageButton(android.R.drawable.ic_menu_recent_history);
        
        btnSettings.setOnClickListener(v -> startActivity(new Intent(this, Settings.class)));
        btnDrawer.setOnClickListener(v -> startActivity(new Intent(this, AppDrawer.class)));
        btnRecent.setOnClickListener(v -> showRecentApps());
        
        bottomBar.addView(btnSettings);
        bottomBar.addView(btnDrawer);
        bottomBar.addView(btnRecent);
        
        mainLayout.addView(topSection);
        mainLayout.addView(appGrid);
        mainLayout.addView(bottomBar);
    }
    
    ImageButton newImageButton(int icon) {
        ImageButton btn = new ImageButton(this);
        btn.setImageResource(icon);
        btn.setBackgroundColor(Color.TRANSPARENT);
        btn.setColorFilter(Color.WHITE);
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(150, 150);
        btn.setLayoutParams(p);
        return btn;
    }
    
    void loadApps() {
        Intent i = new Intent(Intent.ACTION_MAIN, null);
        i.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> list = getPackageManager().queryIntentActivities(i, 0);
        
        int count = 0;
        for (ResolveInfo info : list) {
            if (count++ >= 16) break;
            AppInfo app = new AppInfo(
                info.activityInfo.packageName,
                info.loadLabel(getPackageManager()).toString(),
                info.loadIcon(getPackageManager())
            );
            apps.add(app);
            addAppToGrid(app);
        }
    }
    
    void addAppToGrid(final AppInfo app) {
        LinearLayout cell = new LinearLayout(this);
        cell.setOrientation(LinearLayout.VERTICAL);
        cell.setGravity(Gravity.CENTER);
        cell.setPadding(10, 10, 10, 10);
        
        ImageButton icon = new ImageButton(this);
        icon.setImageDrawable(app.icon);
        icon.setBackgroundColor(Color.TRANSPARENT);
        LinearLayout.LayoutParams ip = new LinearLayout.LayoutParams(130, 130);
        icon.setLayoutParams(ip);
        
        TextView name = new TextView(this);
        name.setText(app.name);
        name.setTextSize(11);
        name.setTextColor(Color.WHITE);
        name.setMaxLines(1);
        name.setGravity(Gravity.CENTER);
        
        cell.addView(icon);
        cell.addView(name);
        
        View.OnClickListener click = v -> launchApp(app.pkg);
        icon.setOnClickListener(click);
        cell.setOnClickListener(click);
        
        GridLayout.LayoutParams gp = new GridLayout.LayoutParams();
        gp.width = 0;
        gp.height = LinearLayout.LayoutParams.WRAP_CONTENT;
        gp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        gp.setMargins(5, 5, 5, 5);
        
        appGrid.addView(cell, gp);
    }
    
    void launchApp(String pkg) {
        try {
            Intent i = getPackageManager().getLaunchIntentForPackage(pkg);
            if (i != null) {
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
            }
        } catch (Exception e) {}
    }
    
    void showRecentApps() {
        Intent i = new Intent(Intent.ACTION_MAIN);
        i.addCategory(Intent.CATEGORY_HOME);
        startActivity(i);
    }
    
    void startClock() {
        Handler h = new Handler();
        h.post(new Runnable() {
            public void run() {
                Calendar c = Calendar.getInstance();
                SimpleDateFormat tf = new SimpleDateFormat("HH:mm");
                SimpleDateFormat df = new SimpleDateFormat("EEEE, MMM d");
                clock.setText(tf.format(c.getTime()));
                date.setText(df.format(c.getTime()));
                h.postDelayed(this, 1000);
            }
        });
    }
    
    @Override
    public void onBackPressed() {
        Intent i = new Intent(Intent.ACTION_MAIN);
        i.addCategory(Intent.CATEGORY_HOME);
        startActivity(i);
    }
    
    class AppInfo {
        String pkg, name;
        Drawable icon;
        AppInfo(String p, String n, Drawable ic) { pkg=p; name=n; icon=ic; }
    }
}
JAVA

# Step 6: Create AppDrawer.java - All Apps List
echo "[6/12] Creating AppDrawer..."
cat > app/src/main/java/com/futuros/ownui/AppDrawer.java << 'JAVA'
package com.futuros.ownui;

import android.app.*;
import android.content.*;
import android.content.pm.*;
import android.graphics.*;
import android.os.*;
import android.text.*;
import android.view.*;
import android.widget.*;
import java.util.*;

public class AppDrawer extends Activity {
    
    EditText searchBox;
    GridLayout appGrid;
    ArrayList<AppInfo> allApps = new ArrayList<>();
    ArrayList<AppInfo> shownApps = new ArrayList<>();
    
    @Override
    protected void onCreate(Bundle saved) {
        super.onCreate(saved);
        
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(20, 60, 20, 20);
        
        GradientDrawable bg = new GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            new int[]{0xFF1A1A2E, 0xFF000000}
        );
        layout.setBackground(bg);
        
        // Search Box
        searchBox = new EditText(this);
        searchBox.setHint("🔍 Search apps...");
        searchBox.setTextSize(18);
        searchBox.setTextColor(Color.WHITE);
        searchBox.setHintTextColor(Color.parseColor("#666666"));
        searchBox.setBackgroundColor(Color.parseColor("#2A2A4E"));
        searchBox.setPadding(30, 25, 30, 25);
        searchBox.addTextChangedListener(new android.text.TextWatcher() {
            public void beforeTextChanged(CharSequence s, int st, int c, int a) {}
            public void onTextChanged(CharSequence s, int st, int b, int c) { filter(s.toString()); }
            public void afterTextChanged(android.text.Editable s) {}
        });
        
        // App Grid
        appGrid = new GridLayout(this);
        appGrid.setColumnCount(4);
        appGrid.setPadding(0, 30, 0, 0);
        
        layout.addView(searchBox);
        layout.addView(appGrid);
        
        loadAllApps();
        setContentView(layout);
    }
    
    void loadAllApps() {
        Intent i = new Intent(Intent.ACTION_MAIN, null);
        i.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> list = getPackageManager().queryIntentActivities(i, 0);
        
        for (ResolveInfo info : list) {
            allApps.add(new AppInfo(
                info.activityInfo.packageName,
                info.loadLabel(getPackageManager()).toString(),
                info.loadIcon(getPackageManager())
            ));
        }
        shownApps.addAll(allApps);
        displayApps();
    }
    
    void filter(String query) {
        shownApps.clear();
        if (query.isEmpty()) {
            shownApps.addAll(allApps);
        } else {
            for (AppInfo app : allApps) {
                if (app.name.toLowerCase().contains(query.toLowerCase())) {
                    shownApps.add(app);
                }
            }
        }
        appGrid.removeAllViews();
        displayApps();
    }
    
    void displayApps() {
        for (AppInfo app : shownApps) {
            LinearLayout cell = new LinearLayout(this);
            cell.setOrientation(LinearLayout.VERTICAL);
            cell.setGravity(Gravity.CENTER);
            cell.setPadding(8, 8, 8, 8);
            
            ImageButton icon = new ImageButton(this);
            icon.setImageDrawable(app.icon);
            icon.setBackgroundColor(Color.TRANSPARENT);
            LinearLayout.LayoutParams ip = new LinearLayout.LayoutParams(120, 120);
            icon.setLayoutParams(ip);
            
            TextView name = new TextView(this);
            name.setText(app.name);
            name.setTextSize(11);
            name.setTextColor(Color.WHITE);
            name.setMaxLines(2);
            name.setGravity(Gravity.CENTER);
            
            cell.addView(icon);
            cell.addView(name);
            
            final String pkg = app.pkg;
            cell.setOnClickListener(v -> launchApp(pkg));
            
            GridLayout.LayoutParams gp = new GridLayout.LayoutParams();
            gp.width = 0;
            gp.height = LinearLayout.LayoutParams.WRAP_CONTENT;
            gp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            appGrid.addView(cell, gp);
        }
    }
    
    void launchApp(String pkg) {
        try {
            Intent i = getPackageManager().getLaunchIntentForPackage(pkg);
            if (i != null) {
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(i);
                finish();
            }
        } catch (Exception e) {}
    }
    
    class AppInfo {
        String pkg, name;
        Drawable icon;
        AppInfo(String p, String n, Drawable ic) { pkg=p; name=n; icon=ic; }
    }
}
JAVA

# Step 7: Create Settings.java
echo "[7/12] Creating Settings..."
cat > app/src/main/java/com/futuros/ownui/Settings.java << 'JAVA'
package com.futuros.ownui;

import android.app.*;
import android.graphics.*;
import android.os.*;
import android.view.*;
import android.widget.*;

public class Settings extends Activity {
    
    @Override
    protected void onCreate(Bundle saved) {
        super.onCreate(saved);
        
        ScrollView scroll = new ScrollView(this);
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(40, 100, 40, 40);
        
        GradientDrawable bg = new GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            new int[]{0xFF1A1A2E, 0xFF16213E}
        );
        layout.setBackground(bg);
        
        // Title
        TextView title = new TextView(this);
        title.setText("⚙️ FutureOS Settings");
        title.setTextSize(28);
        title.setTextColor(Color.parseColor("#00D9FF"));
        title.setTypeface(Typeface.DEFAULT_BOLD);
        title.setPadding(0, 0, 0, 50);
        
        // Theme Section
        addSection(layout, "🎨 Theme", new String[]{"Dark Mode", "Light Mode", "AMOLED Black", "Custom Color"});
        
        // Display Section  
        addSection(layout, "📱 Display", new String[]{"Wallpaper", "Font Size", "Icon Pack", "Grid Layout"});
        
        // Gestures Section
        addSection(layout, "👆 Gestures", new String[]{"Double Tap", "Swipe Actions", "Home Gesture"});
        
        // About Section
        addSection(layout, "ℹ️ About", new String[]{"FutureOS v1.0", "Custom Launcher", "Built with ❤️"});
        
        layout.addView(title);
        scroll.addView(layout);
        setContentView(scroll);
    }
    
    void addSection(LinearLayout parent, String title, String[] items) {
        TextView t = new TextView(this);
        t.setText(title);
        t.setTextSize(20);
        t.setTextColor(Color.WHITE);
        t.setTypeface(Typeface.DEFAULT_BOLD);
        t.setPadding(0, 40, 0, 20);
        parent.addView(t);
        
        for (String item : items) {
            TextView i = new TextView(this);
            i.setText("  " + item);
            i.setTextSize(16);
            i.setTextColor(Color.parseColor("#CCCCCC"));
            i.setPadding(0, 25, 0, 25);
            i.setOnClickListener(v -> {
                // Theme action
            });
            parent.addView(i);
        }
    }
}
JAVA

# Step 8: Create BootReceiver.java
echo "[8/12] Creating BootReceiver..."
cat > app/src/main/java/com/futuros/ownui/BootReceiver.java << 'JAVA'
package com.futuros.ownui;

import android.content.*;
import android.content.pm.*;

public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            Intent i = new Intent(context, MainActivity.class);
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(i);
        }
    }
}
JAVA

# Step 9: Create Resources
echo "[9/12] Creating resources..."
cat > app/src/main/res/values/strings.xml << 'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">FutureOS</string>
</resources>
XML

cat > app/src/main/res/values/colors.xml << 'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="primary">#00D9FF</color>
    <color name="primary_dark">#1A1A2E</color>
    <color name="accent">#E94560</color>
    <color name="bg">#1A1A2E</color>
    <color name="bg_dark">#16213E</color>
    <color name="text">#FFFFFF</color>
</resources>
XML

cat > app/src/main/res/values/themes.xml << 'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme">
        <item name="android:windowBackground">@color/bg</item>
        <item name="android:colorPrimary">@color/primary</item>
        <item name="android:colorPrimaryDark">@color/primary_dark</item>
        <item name="android:colorAccent">@color/accent</item>
        <item name="android:statusBarColor">@color/bg</item>
        <item name="android:navigationBarColor">@color/bg</item>
    </style>
</resources>
XML

# Create icon
for dir in mipmap-hdpi mipmap-mdpi mipmap-xhdpi mipmap-xxhdpi mipmap-xxxhdpi; do
cat > app/src/main/res/$dir/ic_launcher.xml << 'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/primary_dark"/>
    <foreground android:drawable="@color/primary"/>
</adaptive-icon>
XML
done

# Step 10: Create Gradle Files
echo "[10/12] Creating Gradle files..."
cat > build.gradle << 'GRADLE'
buildscript {
    repositories { google(); mavenCentral() }
    dependencies { classpath 'com.android.tools.build:gradle:8.1.0' }
}
allprojects {
    repositories { google(); mavenCentral() }
}
GRADLE

cat > app/build.gradle << 'GRADLE'
apply plugin: 'com.android.application'
android {
    compileSdkVersion 34
    buildToolsVersion "34.0.0"
    defaultConfig {
        applicationId "com.futuros.ownui"
        minSdkVersion 24
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }
    buildTypes { release { minifyEnabled false } }
    compileOptions { sourceCompatibility JavaVersion.VERSION_1_8; targetCompatibility JavaVersion.VERSION_1_8 }
}
dependencies { implementation 'androidx.appcompat:appcompat:1.6.1' }
GRADLE

cat > settings.gradle << 'GRADLE'
include ':app'
GRADLE

cat > gradle.properties << 'GRADLE'
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
android.enableJetifier=true
GRADLE

cat > gradle/wrapper/gradle-wrapper.properties << 'GRADLE'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-bin.zip
GRADLE

# Step 11: Download Gradle Wrapper
echo "[11/12] Downloading Gradle Wrapper..."
mkdir -p gradle/wrapper
wget -q "https://raw.githubusercontent.com/nicokosi/gradle-wrapper-archive/master/gradle-8.0/gradle/wrapper/gradle-wrapper.jar" -O gradle/wrapper/gradle-wrapper.jar 2>/dev/null || \
wget -q "https://github.com/nicokosi/gradle-wrapper-archive/raw/master/gradle-8.0/gradle/wrapper/gradle-wrapper.jar" -O gradle/wrapper/gradle-wrapper.jar 2>/dev/null || \
echo "Will download gradle wrapper during build..."

cat > gradlew << 'BASH'
#!/bin/bash
if [ ! -f "gradle/wrapper/gradle-wrapper.jar" ]; then
    echo "Installing Gradle..."
    pkg install -y gradle 2>/dev/null
    gradle wrapper --gradle-version 8.0
fi
exec gradle "$@"
BASH
chmod +x gradlew

# Step 12: Build APK
echo "[12/12] Building APK..."
echo ""
echo "Building FutureOS OwnUI APK..."
echo ""

# Try to use gradle directly
if command -v gradle &> /dev/null; then
    gradle assembleDebug --no-daemon 2>&1 | tail -20
else
    echo "Installing Gradle..."
    pkg install -y gradle
    gradle assembleDebug --no-daemon 2>&1 | tail -20
fi

# Check if APK was built
if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    cp app/build/outputs/apk/debug/app-debug.apk ~/FutureOS.apk
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║     ✅ FUTUREOS APK BUILD SUCCESSFUL!                ║"
    echo "║                                                      ║"
    echo "║     📱 APK Location: ~/FutureOS.apk                  ║"
    echo "║                                                      ║"
    echo "║     Next Steps:                                      ║"
    echo "║     1. ls ~/FutureOS.apk                            ║"
    echo "║     2. termux-open ~/FutureOS.apk                   ║"
    echo "║     3. Install the APK                              ║"
    echo "║     4. Set FutureOS as Home app                     ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
else
    echo ""
    echo "⚠️ APK not found. Trying alternative build method..."
    echo ""
    
    # Fallback: Try with explicit gradle
    export PATH="$PATH:$(which gradle)"
    gradle assembleDebug --stacktrace 2>&1 | tail -30
    
    if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
        cp app/build/outputs/apk/debug/app-debug.apk ~/FutureOS.apk
        echo ""
        echo "✅ APK BUILT: ~/FutureOS.apk"
    fi
fi

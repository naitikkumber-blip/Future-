#!/bin/bash
# ============================================================
# FutureOS Custom Launcher APK Builder
# Build Your Own Android Launcher APK
# ============================================================

echo "╔══════════════════════════════════════════════╗"
echo "║      FutureOS APK Builder v1.0            ║"
echo "║   Build Your Own Custom Launcher APK        ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Step 1: Clean and Create Project
echo "[1/10] Creating project structure..."
rm -rf ~/FutureOS_APK
mkdir -p ~/FutureOS_APK
cd ~/FutureOS_APK

# Step 2: Create Directory Structure
echo "[2/10] Setting up directories..."
mkdir -p app/src/main/java/com/futuros/launcher
mkdir -p app/src/main/res/{layout,drawable,values,mipmap-hdpi,mipmap-mdpi,mipmap-xhdpi,mipmap-xxhdpi,mipmap-xxxhdpi,xml}
mkdir -p gradle/wrapper

# Step 3: Create AndroidManifest.xml
echo "[3/10] Creating AndroidManifest.xml..."

cat > app/src/main/AndroidManifest.xml << 'MANIFEST'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.futuros.launcher"
    android:versionCode="1"
    android:versionName="1.0"
    android:installLocation="internalOnly">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.SET_WALLPAPER" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="com.android.launcher.permission.READ_SETTINGS" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/AppTheme"
        android:enabled="true"
        android:exported="true">

        <!-- Main Activity - Launcher -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTask"
            android:stateNotNeeded="true"
            android:theme="@style/AppTheme"
            android:screenOrientation="unspecified"
            android:windowSoftInputMode="adjustPan">
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.HOME" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.MONKEY" />
                <category android:name="android.intent.category.LAUNCHER_APP" />
            </intent-filter>
        </activity>

        <!-- Settings Activity -->
        <activity
            android:name=".SettingsActivity"
            android:exported="false"
            android:label="FutureOS Settings" />

        <!-- App Drawer Activity -->
        <activity
            android:name=".AppDrawerActivity"
            android:exported="false"
            android:theme="@style/AppTheme.Transparent" />

        <!-- Boot Receiver -->
        <receiver
            android:name=".BootReceiver"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
            </intent-filter>
        </receiver>

    </application>
</manifest>
MANIFEST

# Step 4: Create MainActivity.java
echo "[4/10] Creating MainActivity.java..."

cat > app/src/main/java/com/futuros/launcher/MainActivity.java << 'JAVA'
package com.futuros.launcher;

import android.app.*;
import android.content.*;
import android.content.pm.*;
import android.graphics.*;
import android.graphics.drawable.*;
import android.os.*;
import android.view.*;
import android.widget.*;
import android.util.*;

import java.util.*;
import java.io.*;

public class MainActivity extends Activity {

    private LinearLayout mainLayout;
    private GridLayout appGrid;
    private TextView clockText;
    private TextView dateText;
    private ImageButton settingsBtn;
    private ImageButton appDrawerBtn;
    
    private ArrayList<AppInfo> installedApps = new ArrayList<>();
    private Map<ImageButton, String> appButtons = new HashMap<>();
    
    private static final int COLUMNS = 4;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // Create main layout
        createMainLayout();
        setContentView(mainLayout);
        
        // Load apps
        loadInstalledApps();
        
        // Update clock
        updateClock();
        
        // Setup click listeners
        setupClickListeners();
    }

    private void createMainLayout() {
        mainLayout = new LinearLayout(this);
        mainLayout.setOrientation(LinearLayout.VERTICAL);
        mainLayout.setGravity(Gravity.CENTER_HORIZONTAL);
        
        // Gradient background
        GradientDrawable background = new GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            new int[]{Color.parseColor("#1A1A2E"), Color.parseColor("#16213E")}
        );
        mainLayout.setBackground(background);
        
        // Top bar with clock
        LinearLayout topBar = new LinearLayout(this);
        topBar.setOrientation(LinearLayout.VERTICAL);
        topBar.setGravity(Gravity.CENTER);
        topBar.setPadding(0, 100, 0, 20);
        
        clockText = new TextView(this);
        clockText.setText("00:00");
        clockText.setTextSize(72);
        clockText.setTextColor(Color.WHITE);
        clockText.setTypeface(Typeface.create("sans-serif-light", Typeface.NORMAL));
        
        dateText = new TextView(this);
        dateText.setText("Monday, January 1");
        dateText.setTextSize(16);
        dateText.setTextColor(Color.parseColor("#AAAAAA"));
        
        topBar.addView(clockText);
        topBar.addView(dateText);
        
        // App grid
        appGrid = new GridLayout(this);
        appGrid.setColumnCount(COLUMNS);
        appGrid.setPadding(20, 20, 20, 20);
        
        // Bottom bar
        LinearLayout bottomBar = new LinearLayout(this);
        bottomBar.setOrientation(LinearLayout.HORIZONTAL);
        bottomBar.setGravity(Gravity.CENTER);
        bottomBar.setPadding(0, 20, 0, 60);
        
        settingsBtn = new ImageButton(this);
        settingsBtn.setImageResource(android.R.drawable.ic_menu_preferences);
        settingsBtn.setBackgroundColor(Color.TRANSPARENT);
        settingsBtn.setColorFilter(Color.WHITE);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(120, 120);
        settingsBtn.setLayoutParams(params);
        
        appDrawerBtn = new ImageButton(this);
        appDrawerBtn.setImageResource(android.R.drawable.ic_menu_agenda);
        appDrawerBtn.setBackgroundColor(Color.TRANSPARENT);
        appDrawerBtn.setColorFilter(Color.WHITE);
        appDrawerBtn.setLayoutParams(params);
        
        bottomBar.addView(settingsBtn);
        bottomBar.addView(appDrawerBtn);
        
        mainLayout.addView(topBar);
        mainLayout.addView(appGrid);
        mainLayout.addView(bottomBar);
    }

    private void loadInstalledApps() {
        Intent intent = new Intent(Intent.ACTION_MAIN, null);
        intent.addCategory(Intent.CATEGORY_LAUNCHER);
        
        List<ResolveInfo> apps = getPackageManager().queryIntentActivities(intent, 0);
        
        for (ResolveInfo info : apps) {
            String packageName = info.activityInfo.packageName;
            String appName = info.loadLabel(getPackageManager()).toString();
            Drawable icon = info.loadIcon(getPackageManager());
            
            AppInfo app = new AppInfo(packageName, appName, icon);
            installedApps.add(app);
            
            // Add to grid (limit to 12 for demo)
            if (installedApps.size() <= 12) {
                addAppToGrid(app);
            }
        }
    }

    private void addAppToGrid(AppInfo app) {
        LinearLayout appCell = new LinearLayout(this);
        appCell.setOrientation(LinearLayout.VERTICAL);
        appCell.setGravity(Gravity.CENTER);
        
        int padding = 16;
        appCell.setPadding(padding, padding, padding, padding);
        
        ImageButton appIcon = new ImageButton(this);
        appIcon.setImageDrawable(app.icon);
        appIcon.setBackgroundColor(Color.TRANSPARENT);
        appIcon.setScaleType(ImageView.ScaleType.FIT_CENTER);
        
        LinearLayout.LayoutParams iconParams = new LinearLayout.LayoutParams(144, 144);
        appIcon.setLayoutParams(iconParams);
        
        TextView appName = new TextView(this);
        appName.setText(app.name);
        appName.setTextSize(11);
        appName.setTextColor(Color.WHITE);
        appName.setMaxLines(1);
        appName.setGravity(Gravity.CENTER);
        
        appCell.addView(appIcon);
        appCell.addView(appName);
        
        // Click to launch app
        final String pkgName = app.packageName;
        appIcon.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                launchApp(pkgName);
            }
        });
        
        appCell.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                launchApp(pkgName);
            }
        });
        
        GridLayout.LayoutParams gridParams = new GridLayout.LayoutParams();
        gridParams.width = 0;
        gridParams.height = LinearLayout.LayoutParams.WRAP_CONTENT;
        gridParams.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        gridParams.setMargins(8, 8, 8, 8);
        
        appGrid.addView(appCell, gridParams);
    }

    private void launchApp(String packageName) {
        Intent intent = getPackageManager().getLaunchIntentForPackage(packageName);
        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
    }

    private void updateClock() {
        Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                Calendar cal = Calendar.getInstance();
                
                int hour = cal.get(Calendar.HOUR_OF_DAY);
                int minute = cal.get(Calendar.MINUTE);
                int day = cal.get(Calendar.DAY_OF_MONTH);
                int month = cal.get(Calendar.MONTH);
                int dayOfWeek = cal.get(Calendar.DAY_OF_WEEK);
                
                String[] days = {"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"};
                String[] months = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"};
                
                String time = String.format("%02d:%02d", hour, minute);
                String date = days[dayOfWeek - 1] + ", " + months[month] + " " + day;
                
                clockText.setText(time);
                dateText.setText(date);
                
                handler.postDelayed(this, 1000);
            }
        };
        handler.post(runnable);
    }

    private void setupClickListeners() {
        settingsBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, SettingsActivity.class);
                startActivity(intent);
            }
        });
        
        appDrawerBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(MainActivity.this, AppDrawerActivity.class);
                startActivity(intent);
            }
        });
    }

    @Override
    public void onBackPressed() {
        // Go to home instead of closing
        Intent home = new Intent(Intent.ACTION_MAIN);
        home.addCategory(Intent.CATEGORY_HOME);
        startActivity(home);
    }

    // App Info Class
    private class AppInfo {
        String packageName;
        String name;
        Drawable icon;
        
        AppInfo(String pkg, String n, Drawable i) {
            packageName = pkg;
            name = n;
            icon = i;
        }
    }
}
JAVA

# Step 5: Create SettingsActivity.java
echo "[5/10] Creating SettingsActivity.java..."

cat > app/src/main/java/com/futuros/launcher/SettingsActivity.java << 'JAVA'
package com.futuros.launcher;

import android.app.*;
import android.os.*;
import android.view.*;
import android.widget.*;
import android.graphics.*;

public class SettingsActivity extends Activity {

    private LinearLayout layout;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(40, 100, 40, 40);
        
        GradientDrawable background = new GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            new int[]{Color.parseColor("#1A1A2E"), Color.parseColor("#16213E")}
        );
        layout.setBackground(background);
        
        // Title
        TextView title = new TextView(this);
        title.setText("FutureOS Settings");
        title.setTextSize(28);
        title.setTextColor(Color.parseColor("#00D9FF"));
        title.setTypeface(Typeface.DEFAULT_BOLD);
        title.setPadding(0, 0, 0, 40);
        
        // Theme Section
        TextView themeLabel = new TextView(this);
        themeLabel.setText("Theme");
        themeLabel.setTextSize(18);
        themeLabel.setTextColor(Color.WHITE);
        themeLabel.setPadding(0, 20, 0, 10);
        
        String[] themes = {"Dark", "Light", "AMOLED Black", "Custom"};
        for (String theme : themes) {
            addOption(theme);
        }
        
        // Wallpaper Section
        TextView wallpaperLabel = new TextView(this);
        wallpaperLabel.setText("Wallpaper");
        wallpaperLabel.setTextSize(18);
        wallpaperLabel.setTextColor(Color.WHITE);
        wallpaperLabel.setPadding(0, 30, 0, 10);
        
        String[] wallpapers = {"Set Wallpaper", "Live Wallpapers", "Wallpaper Changer"};
        for (String wp : wallpapers) {
            addOption(wp);
        }
        
        // About Section
        TextView aboutLabel = new TextView(this);
        aboutLabel.setText("About");
        aboutLabel.setTextSize(18);
        aboutLabel.setTextColor(Color.WHITE);
        aboutLabel.setPadding(0, 30, 0, 10);
        
        addOption("FutureOS v1.0");
        addOption("Custom Launcher");
        
        layout.addView(title);
        layout.addView(themeLabel);
        layout.addView(wallpaperLabel);
        layout.addView(aboutLabel);
        
        setContentView(layout);
    }

    private void addOption(String text) {
        TextView tv = new TextView(this);
        tv.setText(text);
        tv.setTextSize(16);
        tv.setTextColor(Color.parseColor("#CCCCCC"));
        tv.setPadding(0, 20, 0, 20);
        
        tv.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Toast.makeText(SettingsActivity.this, text, Toast.LENGTH_SHORT).show();
            }
        });
        
        layout.addView(tv);
    }
}
JAVA

# Step 6: Create AppDrawerActivity.java
echo "[6/10] Creating AppDrawerActivity.java..."

cat > app/src/main/java/com/futuros/launcher/AppDrawerActivity.java << 'JAVA'
package com.futuros.launcher;

import android.app.*;
import android.content.*;
import android.content.pm.*;
import android.graphics.*;
import android.os.*;
import android.text.*;
import android.view.*;
import android.widget.*;
import android.inputmethodservice.*;

import java.util.*;

public class AppDrawerActivity extends Activity {

    private EditText searchBox;
    private GridLayout appGrid;
    private ArrayList<AppInfo> allApps = new ArrayList<>();
    private ArrayList<AppInfo> filteredApps = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(20, 60, 20, 20);
        
        GradientDrawable background = new GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            new int[]{Color.parseColor("#1A1A2E"), Color.parseColor("#000000")}
        );
        layout.setBackground(background);
        
        // Search box
        searchBox = new EditText(this);
        searchBox.setHint("Search apps...");
        searchBox.setTextSize(18);
        searchBox.setTextColor(Color.WHITE);
        searchBox.setHintTextColor(Color.parseColor("#888888"));
        searchBox.setBackgroundColor(Color.parseColor("#2A2A4E"));
        searchBox.setPadding(30, 20, 30, 20);
        searchBox.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                filterApps(s.toString());
            }
            
            @Override
            public void afterTextChanged(Editable s) {}
        });
        
        // App grid
        appGrid = new GridLayout(this);
        appGrid.setColumnCount(4);
        appGrid.setPadding(0, 20, 0, 0);
        
        layout.addView(searchBox);
        layout.addView(appGrid);
        
        loadAllApps();
        
        setContentView(layout);
    }

    private void loadAllApps() {
        Intent intent = new Intent(Intent.ACTION_MAIN, null);
        intent.addCategory(Intent.CATEGORY_LAUNCHER);
        
        List<ResolveInfo> apps = getPackageManager().queryIntentActivities(intent, 0);
        
        for (ResolveInfo info : apps) {
            String pkg = info.activityInfo.packageName;
            String name = info.loadLabel(getPackageManager()).toString();
            Drawable icon = info.loadIcon(getPackageManager());
            
            AppInfo app = new AppInfo(pkg, name, icon);
            allApps.add(app);
            filteredApps.add(app);
        }
        
        displayApps(filteredApps);
    }

    private void filterApps(String query) {
        filteredApps.clear();
        
        if (TextUtils.isEmpty(query)) {
            filteredApps.addAll(allApps);
        } else {
            for (AppInfo app : allApps) {
                if (app.name.toLowerCase().contains(query.toLowerCase())) {
                    filteredApps.add(app);
                }
            }
        }
        
        appGrid.removeAllViews();
        displayApps(filteredApps);
    }

    private void displayApps(ArrayList<AppInfo> apps) {
        for (AppInfo app : apps) {
            addAppToGrid(app);
        }
    }

    private void addAppToGrid(final AppInfo app) {
        LinearLayout cell = new LinearLayout(this);
        cell.setOrientation(LinearLayout.VERTICAL);
        cell.setGravity(Gravity.CENTER);
        cell.setPadding(8, 8, 8, 8);
        
        ImageButton icon = new ImageButton(this);
        icon.setImageDrawable(app.icon);
        icon.setBackgroundColor(Color.TRANSPARENT);
        
        LinearLayout.LayoutParams iconParams = new LinearLayout.LayoutParams(120, 120);
        icon.setLayoutParams(iconParams);
        
        TextView name = new TextView(this);
        name.setText(app.name);
        name.setTextSize(11);
        name.setTextColor(Color.WHITE);
        name.setMaxLines(2);
        name.setGravity(Gravity.CENTER);
        
        cell.addView(icon);
        cell.addView(name);
        
        cell.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = getPackageManager().getLaunchIntentForPackage(app.packageName);
                if (intent != null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(intent);
                    finish();
                }
            }
        });
        
        GridLayout.LayoutParams params = new GridLayout.LayoutParams();
        params.width = 0;
        params.height = LinearLayout.LayoutParams.WRAP_CONTENT;
        params.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
        
        appGrid.addView(cell, params);
    }

    private class AppInfo {
        String packageName;
        String name;
        Drawable icon;
        
        AppInfo(String pkg, String n, Drawable i) {
            packageName = pkg;
            name = n;
            icon = i;
        }
    }
}
JAVA

# Step 7: Create BootReceiver.java
echo "[7/10] Creating BootReceiver.java..."

cat > app/src/main/java/com/futuros/launcher/BootReceiver.java << 'JAVA'
package com.futuros.launcher;

import android.content.*;
import android.content.pm.*;

public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction())) {
            // Launch main activity after boot
            Intent i = new Intent(context, MainActivity.class);
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(i);
        }
    }
}
JAVA

# Step 8: Create Resources
echo "[8/10] Creating resources..."

# strings.xml
cat > app/src/main/res/values/strings.xml << 'STRINGS'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">FutureOS</string>
</resources>
STRINGS

# colors.xml
cat > app/src/main/res/values/colors.xml << 'COLORS'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="primary">#00D9FF</color>
    <color name="primary_dark">#1A1A2E</color>
    <color name="accent">#E94560</color>
    <color name="background">#1A1A2E</color>
    <color name="background_dark">#16213E</color>
    <color name="text_primary">#FFFFFF</color>
    <color name="text_secondary">#AAAAAA</color>
</resources>
COLORS

# themes.xml
cat > app/src/main/res/values/themes.xml << 'THEMES'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme">
        <item name="android:windowBackground">@color/background</item>
        <item name="android:colorPrimary">@color/primary</item>
        <item name="android:colorPrimaryDark">@color/primary_dark</item>
        <item name="android:colorAccent">@color/accent</item>
        <item name="android:statusBarColor">@color/background</item>
        <item name="android:navigationBarColor">@color/background</item>
    </style>
    
    <style name="AppTheme.Transparent">
        <item name="android:windowBackground">@android:color/transparent</item>
        <item name="android:windowIsTranslucent">true</item>
    </style>
</resources>
THEMES

# Create simple launcher icons (PNG format would need actual images)
cat > app/src/main/res/mipmap-hdpi/ic_launcher.xml << 'ICON'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/primary_dark"/>
    <foreground android:drawable="@color/primary"/>
</adaptive-icon>
ICON

cp app/src/main/res/mipmap-hdpi/ic_launcher.xml app/src/main/res/mipmap-mdpi/ic_launcher.xml
cp app/src/main/res/mipmap-hdpi/ic_launcher.xml app/src/main/res/mipmap-xhdpi/ic_launcher.xml
cp app/src/main/res/mipmap-hdpi/ic_launcher.xml app/src/main/res/mipmap-xxhdpi/ic_launcher.xml
cp app/src/main/res/mipmap-hdpi/ic_launcher.xml app/src/main/res/mipmap-xxxhdpi/ic_launcher.xml
cp app/src/main/res/mipmap-hdpi/ic_launcher.xml app/src/main/res/mipmap-hdpi/ic_launcher_round.xml
cp app/src/main/res/mipmap-hdpi/ic_launcher.xml app/src/main/res/mipmap-mdpi/ic_launcher_round.xml
cp app/src/main/res/mipmap-hdpi/ic_launcher.xml app/src/main/res/mipmap-xhdpi/ic_launcher_round.xml
cp app/src/main/res/mipmap-hdpi/ic_launcher.xml app/src/main/res/mipmap-xxhdpi/ic_launcher_round.xml
cp app/src/main/res/mipmap-hdpi/ic_launcher.xml app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.xml

# Step 9: Create Gradle Files
echo "[9/10] Creating Gradle build files..."

# build.gradle (project level)
cat > build.gradle << 'GRADLE'
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
GRADLE

# build.gradle (app level)
cat > app/build.gradle << 'GRADLE'
apply plugin: 'com.android.application'

android {
    compileSdkVersion 34
    buildToolsVersion "34.0.0"
    
    defaultConfig {
        applicationId "com.futuros.launcher"
        minSdkVersion 24
        targetSdkVersion 34
        versionCode 1
        versionName "1.0"
    }
    
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
}
GRADLE

# settings.gradle
cat > settings.gradle << 'SETTINGS'
include ':app'
SETTINGS

# gradle.properties
cat > gradle.properties << 'PROPS'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.enableJetifier=true
PROPS

# gradle-wrapper.properties
cat > gradle/wrapper/gradle-wrapper.properties << 'WRAPPER'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
WRAPPER

# Step 10: Create Build Script
echo "[10/10] Creating build instructions..."

cat > BUILD_INSTRUCTIONS.txt << 'BUILD'
╔══════════════════════════════════════════════════════════╗
║          FutureOS APK Build Instructions              ║
╚══════════════════════════════════════════════════════════╝

OPTION 1: Build on Your Phone (Termux)
=====================================
1. Install Termux packages:
   pkg update && pkg upgrade -y
   pkg install -y openjdk-17 gradle

2. Navigate to project:
   cd ~/FutureOS_APK

3. Build APK:
   ./gradlew assembleDebug

4. Find APK at:
   app/build/outputs/apk/debug/app-debug.apk

OPTION 2: Build on Computer (Recommended)
=========================================
1. Copy project folder to computer:
   - Copy ~/FutureOS_APK folder

2. Install Android Studio:
   - Download from https://developer.android.com/studio

3. Open project in Android Studio:
   - File > Open > Select FutureOS_APK folder

4. Build APK:
   - Build > Build Bundle(s) / APK(s) > Build APK(s)

5. Transfer APK to phone and install!

OPTION 3: Online Build (No Software)
===================================
1. Go to: https://app.outverse.com/
2. Upload project files
3. Build in browser

═══════════════════════════════════════════════════════════
INSTALLING THE APK
═══════════════════════════════════════════════════════════

1. Transfer APK to phone
2. Enable "Install from Unknown Sources" in Settings
3. Open APK file
4. Tap "Install"
5. Set FutureOS as your Home app when prompted!

═══════════════════════════════════════════════════════════
BUILD
═══════════════════════════════════════════════════════════
BUILD

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║          ✅ FutureOS APK Project Created!             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Project Location: ~/FutureOS_APK"
echo ""
echo "Next Steps:"
echo "1. cd ~/FutureOS_APK"
echo "2. pkg install -y gradle (if on phone)"
echo "3. ./gradlew assembleDebug"
echo ""
echo "Or copy to computer with Android Studio!"
echo ""

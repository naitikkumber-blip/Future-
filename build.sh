#!/bin/bash
# FutureOS - ONE COMMAND BUILD EVERYTHING
# Run this ONE line in Termux:
# curl -fsSL https://raw.githubusercontent.com/naitikkumber-blip/Future-/main/build.sh | bash

echo "╔══════════════════════════════════════════════════════╗"
echo "║   FutureOS - Building Your Custom UI Now!       ║"
echo "╚══════════════════════════════════════════════════════╝"

# Install packages
pkg update && pkg upgrade -y 2>/dev/null
pkg install -y openjdk-17 gradle wget unzip 2>/dev/null

# Create project
rm -rf ~/FutureOS_Build 2>/dev/null
mkdir -p ~/FutureOS_Build
cd ~/FutureOS_Build

# Create all directories
mkdir -p app/src/main/java/com/futuros/ui
mkdir -p app/src/main/res/{values,mipmap-hdpi}

# Create AndroidManifest.xml
cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.futuros.ui">
<uses-permission android:name="android.permission.INTERNET"/>
<application android:allowBackup="true" android:icon="@mipmap/ic_launcher" android:label="FutureOS" android:theme="@style/AppTheme">
<activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTask">
<intent-filter>
<action android:name="android.intent.action.MAIN"/>
<category android:name="android.intent.category.HOME"/>
<category android:name="android.intent.category.DEFAULT"/>
</intent-filter>
</activity>
</application>
</manifest>
EOF

# Create MainActivity.java
cat > app/src/main/java/com/futuros/ui/MainActivity.java << 'EOF'
package com.futuros.ui;

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
    LinearLayout main;
    GridLayout grid;
    TextView clock,date;
    ArrayList<AppInfo> apps=new ArrayList<>();
    
    @Override
    protected void onCreate(Bundle s){
        super.onCreate(s);
        
        main=new LinearLayout(this);
        main.setOrientation(LinearLayout.VERTICAL);
        main.setGravity(Gravity.CENTER_HORIZONTAL);
        
        GradientDrawable bg=new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,new int[]{0xFF1A1A2E,0xFF16213E,0xFF0F3460});
        main.setBackground(bg);
        
        // CLOCK
        LinearLayout top=new LinearLayout(this);
        top.setOrientation(LinearLayout.VERTICAL);
        top.setGravity(Gravity.CENTER);
        top.setPadding(0,150,0,50);
        
        clock=new TextView(this);
        clock.setText("00:00");
        clock.setTextSize(80);
        clock.setTextColor(Color.WHITE);
        clock.setTypeface(Typeface.create("sans-serif-light",Typeface.NORMAL));
        
        date=new TextView(this);
        date.setText("Loading...");
        date.setTextSize(20);
        date.setTextColor(Color.parseColor("#888888"));
        
        top.addView(clock);
        top.addView(date);
        
        // GRID
        grid=new GridLayout(this);
        grid.setColumnCount(4);
        grid.setPadding(30,20,30,20);
        
        // BOTTOM BAR
        LinearLayout bottom=new LinearLayout(this);
        bottom.setOrientation(LinearLayout.HORIZONTAL);
        bottom.setGravity(Gravity.CENTER);
        bottom.setPadding(0,30,0,100);
        
        ImageButton home=newImageButton(android.R.drawable.ic_menu_home);
        ImageButton apps=newImageButton(android.R.drawable.ic_menu_agenda);
        ImageButton settings=newImageButton(android.R.drawable.ic_menu_preferences);
        
        home.setOnClickListener(v->{});
        apps.setOnClickListener(v->startActivity(new Intent(this,AppDrawer.class)));
        settings.setOnClickListener(v->startActivity(new Intent(this,Settings.class)));
        
        bottom.addView(home);
        bottom.addView(apps);
        bottom.addView(settings);
        
        main.addView(top);
        main.addView(grid);
        main.addView(bottom);
        setContentView(main);
        
        loadApps();
        startClock();
    }
    
    ImageButton newImageButton(int i){
        ImageButton b=new ImageButton(this);
        b.setImageResource(i);
        b.setBackgroundColor(Color.TRANSPARENT);
        b.setColorFilter(Color.WHITE);
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(150,150);
        b.setLayoutParams(p);
        return b;
    }
    
    void loadApps(){
        Intent i=new Intent(Intent.ACTION_MAIN,null);
        i.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> l=getPackageManager().queryIntentActivities(i,0);
        int c=0;
        for(ResolveInfo info:l){
            if(c++>=12)break;
            AppInfo a=new AppInfo(info.activityInfo.packageName,info.loadLabel(getPackageManager()).toString(),info.loadIcon(getPackageManager()));
            apps.add(a);
            addApp(a);
        }
    }
    
    void addApp(final AppInfo app){
        LinearLayout cell=new LinearLayout(this);
        cell.setOrientation(LinearLayout.VERTICAL);
        cell.setGravity(Gravity.CENTER);
        cell.setPadding(10,10,10,10);
        
        ImageButton icon=new ImageButton(this);
        icon.setImageDrawable(app.icon);
        icon.setBackgroundColor(Color.TRANSPARENT);
        LinearLayout.LayoutParams ip=new LinearLayout.LayoutParams(130,130);
        icon.setLayoutParams(ip);
        
        TextView name=new TextView(this);
        name.setText(app.name);
        name.setTextSize(11);
        name.setTextColor(Color.WHITE);
        name.setMaxLines(1);
        name.setGravity(Gravity.CENTER);
        
        cell.addView(icon);
        cell.addView(name);
        
        View.OnClickListener click=v->{
            try{
                Intent i=getPackageManager().getLaunchIntentForPackage(app.pkg);
                if(i!=null){i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);startActivity(i);}
            }catch(Exception e){}
        };
        icon.setOnClickListener(click);
        cell.setOnClickListener(click);
        
        GridLayout.LayoutParams gp=new GridLayout.LayoutParams();
        gp.width=0;
        gp.height=LinearLayout.LayoutParams.WRAP_CONTENT;
        gp.columnSpec=GridLayout.spec(GridLayout.UNDEFINED,1f);
        gp.setMargins(5,5,5,5);
        
        grid.addView(cell,gp);
    }
    
    void startClock(){
        Handler h=new Handler();
        h.post(new Runnable(){
            public void run(){
                Calendar c=Calendar.getInstance();
                SimpleDateFormat tf=new SimpleDateFormat("HH:mm");
                SimpleDateFormat df=new SimpleDateFormat("EEEE, MMM d");
                clock.setText(tf.format(c.getTime()));
                date.setText(df.format(c.getTime()));
                h.postDelayed(this,1000);
            }
        });
    }
    
    @Override
    public void onBackPressed(){
        Intent i=new Intent(Intent.ACTION_MAIN);
        i.addCategory(Intent.CATEGORY_HOME);
        startActivity(i);
    }
    
    class AppInfo{
        String pkg,name;
        Drawable icon;
        AppInfo(String p,String n,Drawable i){pkg=p;name=n;icon=i;}
    }
}
EOF

# Create AppDrawer.java
cat > app/src/main/java/com/futuros/ui/AppDrawer.java << 'EOF'
package com.futuros.ui;

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
    EditText search;
    GridLayout grid;
    ArrayList<AppInfo> all=new ArrayList<>();
    
    @Override
    protected void onCreate(Bundle s){
        super.onCreate(s);
        
        LinearLayout l=new LinearLayout(this);
        l.setOrientation(LinearLayout.VERTICAL);
        l.setPadding(20,60,20,20);
        l.setBackground(new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,new int[]{0xFF1A1A2E,0xFF000000}));
        
        search=new EditText(this);
        search.setHint("Search apps...");
        search.setTextSize(18);
        search.setTextColor(Color.WHITE);
        search.setHintTextColor(Color.parseColor("#666666"));
        search.setBackgroundColor(Color.parseColor("#2A2A4E"));
        search.setPadding(30,25,30,25);
        search.addTextChangedListener(new TextWatcher(){
            public void beforeTextChanged(CharSequence s,int st,int c,int a){}
            public void onTextChanged(CharSequence s,int st,int b,int c){filter(s.toString());}
            public void afterTextChanged(Editable s){}
        });
        
        grid=new GridLayout(this);
        grid.setColumnCount(4);
        grid.setPadding(0,30,0,0);
        
        l.addView(search);
        l.addView(grid);
        
        loadApps();
        setContentView(l);
    }
    
    void loadApps(){
        Intent i=new Intent(Intent.ACTION_MAIN,null);
        i.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> list=getPackageManager().queryIntentActivities(i,0);
        for(ResolveInfo info:list){
            all.add(new AppInfo(info.activityInfo.packageName,info.loadLabel(getPackageManager()).toString(),info.loadIcon(getPackageManager())));
        }
        display();
    }
    
    void filter(String q){
        ArrayList<AppInfo> f=new ArrayList<>();
        if(q.isEmpty())f.addAll(all);
        else for(AppInfo a:all)if(a.name.toLowerCase().contains(q.toLowerCase()))f.add(a);
        grid.removeAllViews();
        for(AppInfo a:f)addApp(a);
    }
    
    void display(){for(AppInfo a:all)addApp(a);}
    
    void addApp(final AppInfo app){
        LinearLayout cell=new LinearLayout(this);
        cell.setOrientation(LinearLayout.VERTICAL);
        cell.setGravity(Gravity.CENTER);
        cell.setPadding(8,8,8,8);
        
        ImageButton icon=new ImageButton(this);
        icon.setImageDrawable(app.icon);
        icon.setBackgroundColor(Color.TRANSPARENT);
        LinearLayout.LayoutParams ip=new LinearLayout.LayoutParams(120,120);
        icon.setLayoutParams(ip);
        
        TextView name=new TextView(this);
        name.setText(app.name);
        name.setTextSize(11);
        name.setTextColor(Color.WHITE);
        name.setMaxLines(2);
        name.setGravity(Gravity.CENTER);
        
        cell.addView(icon);
        cell.addView(name);
        
        cell.setOnClickListener(v->{
            try{
                Intent i=getPackageManager().getLaunchIntentForPackage(app.pkg);
                if(i!=null){i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);startActivity(i);finish();}
            }catch(Exception e){}
        });
        
        GridLayout.LayoutParams gp=new GridLayout.LayoutParams();
        gp.width=0;
        gp.height=LinearLayout.LayoutParams.WRAP_CONTENT;
        gp.columnSpec=GridLayout.spec(GridLayout.UNDEFINED,1f);
        grid.addView(cell,gp);
    }
    
    class AppInfo{String pkg,name;Drawable icon;AppInfo(String p,String n,Drawable i){pkg=p;name=n;icon=i;}}
}
EOF

# Create Settings.java
cat > app/src/main/java/com/futuros/ui/Settings.java << 'EOF'
package com.futuros.ui;

import android.app.*;
import android.graphics.*;
import android.os.*;
import android.view.*;
import android.widget.*;

public class Settings extends Activity {
    @Override
    protected void onCreate(Bundle s){
        super.onCreate(s);
        ScrollView sv=new ScrollView(this);
        LinearLayout l=new LinearLayout(this);
        l.setOrientation(LinearLayout.VERTICAL);
        l.setPadding(40,100,40,40);
        l.setBackground(new GradientDrawable(GradientDrawable.Orientation.TOP_BOTTOM,new int[]{0xFF1A1A2E,0xFF16213E}));
        
        TextView t=new TextView(this);
        t.setText("⚙️ FutureOS Settings");
        t.setTextSize(28);
        t.setTextColor(Color.parseColor("#00D9FF"));
        t.setTypeface(Typeface.DEFAULT_BOLD);
        t.setPadding(0,0,0,50);
        l.addView(t);
        
        String[] sections={"🎨 Theme","📱 Display","👆 Gestures","ℹ️ About"};
        for(String sec:sections){
            TextView sec_t=new TextView(this);
            sec_t.setText(sec);
            sec_t.setTextSize(20);
            sec_t.setTextColor(Color.WHITE);
            sec_t.setTypeface(Typeface.DEFAULT_BOLD);
            sec_t.setPadding(0,40,0,20);
            l.addView(sec_t);
            
            for(int i=0;i<4;i++){
                TextView opt=new TextView(this);
                opt.setText("  Option "+(i+1));
                opt.setTextSize(16);
                opt.setTextColor(Color.parseColor("#CCCCCC"));
                opt.setPadding(0,25,0,25);
                l.addView(opt);
            }
        }
        
        sv.addView(l);
        setContentView(sv);
    }
}
EOF

# Create Resources
cat > app/src/main/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources><string name="app_name">FutureOS</string></resources>
EOF

cat > app/src/main/res/values/colors.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
<color name="primary">#00D9FF</color>
<color name="primary_dark">#1A1A2E</color>
<color name="accent">#E94560</color>
<color name="bg">#1A1A2E</color>
</resources>
EOF

cat > app/src/main/res/values/themes.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
<style name="AppTheme">
<item name="android:windowBackground">@color/bg</item>
<item name="android:colorPrimary">@color/primary</item>
<item name="android:colorPrimaryDark">@color/primary_dark</item>
<item name="android:colorAccent">@color/accent</item>
<item name="android:statusBarColor">@color/bg</item>
</style>
</resources>
EOF

cat > app/src/main/res/mipmap-hdpi/ic_launcher.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
<background android:drawable="@color/primary_dark"/>
<foreground android:drawable="@color/primary"/>
</adaptive-icon>
EOF

# Create Gradle Files
cat > build.gradle << 'EOF'
buildscript{repositories{google();mavenCentral()};dependencies{classpath 'com.android.tools.build:gradle:8.1.0'}}
allprojects{repositories{google();mavenCentral()}}
EOF

cat > app/build.gradle << 'EOF'
apply plugin:'com.android.application'
android{compileSdkVersion 34;buildToolsVersion "34.0.0";defaultConfig{applicationId "com.futuros.ui";minSdkVersion 24;targetSdkVersion 34;versionCode 1;versionName "1.0"};buildTypes{release{minifyEnabled false}};compileOptions{sourceCompatibility JavaVersion.VERSION_1_8;targetCompatibility JavaVersion.VERSION_1_8}}
dependencies{implementation 'androidx.appcompat:appcompat:1.6.1'}
EOF

cat > settings.gradle << 'EOF'
include ':app'
EOF

cat > gradle.properties << 'EOF'
org.gradle.jvmargs=-Xmx2048m
android.useAndroidX=true
android.enableJetifier=true
EOF

cat > gradle/wrapper/gradle-wrapper.properties << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-bin.zip
EOF

# Build APK
echo ""
echo "🔨 Building APK..."
echo ""

cd ~/FutureOS_Build
gradle wrapper --gradle-version 8.0 2>/dev/null
./gradlew assembleDebug --no-daemon 2>&1 | tail -5

if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    cp app/build/outputs/apk/debug/app-debug.apk ~/FutureOS.apk
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                                                      ║"
    echo "║     ✅ SUCCESS! FutureOS APK Ready!                  ║"
    echo "║                                                      ║"
    echo "║     📱 ~/FutureOS.apk                              ║"
    echo "║                                                      ║"
    echo "║     Install and set as Home app!                    ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
else
    echo "⚠️ Build issue - trying alternative..."
    gradle assembleDebug --stacktrace 2>&1 | tail -10
    if [ -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
        cp app/build/outputs/apk/debug/app-debug.apk ~/FutureOS.apk
        echo "✅ APK Ready: ~/FutureOS.apk"
    fi
fi

#!/bin/bash
# FutureOS ONE COMMAND INSTALL - Everything in One Go!
curl -fsSL https://raw.githubusercontent.com/naitikkumber-blip/Future-/main/FutureOS_APK_Builder.sh | bash && cd ~/FutureOS_APK && pkg install -y gradle && ./gradlew assembleDebug && cp app/build/outputs/apk/debug/app-debug.apk ~/FutureOS.apk && echo "✅ APK READY: ~/FutureOS.apk"

@echo off
cd android
call gradlew.bat assembleDebug --stacktrace --info > build_full.log 2>&1
echo Done

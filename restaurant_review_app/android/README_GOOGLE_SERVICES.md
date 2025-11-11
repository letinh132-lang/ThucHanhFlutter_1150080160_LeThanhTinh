# Thêm google-services.json
1) Firebase Console → Project settings → Your Apps → Android
2) Package name (ví dụ): com.example.restaurant_review_app
3) Tải file google-services.json và đặt vào: android/app/google-services.json
4) build.gradle: 
   - root: classpath 'com.google.gms:google-services:4.4.2'
   - app: apply plugin: 'com.google.gms.google-services'

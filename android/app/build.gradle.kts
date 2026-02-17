plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.android.agendly" // Asegúrate que coincida con tu paquete
    compileSdk = 35 // Te recomiendo subirlo a 34 para evitar advertencias de Google Play

    ndkVersion = "27.0.12077973"

    compileOptions {
        // Mantenemos Java 17, es lo ideal para Flutter 3.19+
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true 
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.android.agendly"
        // minSdk 21 es obligatorio para desugaring y file_picker
        minSdk = 21 
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Esta línea es la que permite que funciones de Java moderno corran en Android viejo
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
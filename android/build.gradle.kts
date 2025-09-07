// Root build.gradle.kts

plugins {
    // ไม่มีอะไรต้องใส่ตรงนี้สำหรับ root ปกติ
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.0.2") // ปรับตามเวอร์ชัน Android Gradle Plugin ของคุณ
        classpath("com.google.gms:google-services:4.3.15") // สำหรับ Firebase
        // classpath ของ Flutter plugin จะถูกจัดการใน settings.gradle.kts
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// ถ้าต้องการกำหนด build directory ใหม่
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Task สำหรับ clean project
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

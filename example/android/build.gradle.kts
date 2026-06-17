allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/WiseAI-Tech/ekyc110")
            credentials {
                username = "WiseAI-Tech"
                password = "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"
            }
        }
        // Required to resolve WiseAiFaceVerify, a transitive dependency of
        // com.wiseai.ekyc:app pulled in for the Face Verify flow.
        maven {
            name = "GitHubPackages-face-verify"
            url = uri("https://maven.pkg.github.com/WiseAI-Tech/ekyc110-face-verify")
            credentials {
                username = "WiseAI-Tech"
                password = "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"
            }
        }
        maven { url = uri("https://developer.huawei.com/repo/") }
    }
}

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

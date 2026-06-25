allprojects {
    repositories {
        google()
        mavenCentral()
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

subprojects {
    val configureProject = { p: Project ->
        val android = p.extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    val manifestFile = p.file("src/main/AndroidManifest.xml")
                    var ns: String? = null
                    if (manifestFile.exists()) {
                        val manifestText = manifestFile.readText()
                        val packageMatch = Regex("package=\"([^\"]+)\"").find(manifestText)
                        if (packageMatch != null) {
                            ns = packageMatch.groupValues[1]
                        }
                    }
                    if (ns == null) {
                        ns = "com.example.${p.name.replace("-", "_").replace(".", "_")}"
                    }
                    setNamespace.invoke(android, ns)
                }
            } catch (e: Exception) {
                // Ignore errors to ensure the build config completes safely
            }
        }
    }

    if (project.state.executed) {
        configureProject(project)
    } else {
        project.afterEvaluate {
            configureProject(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


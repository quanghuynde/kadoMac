val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    afterEvaluate {
        // Fix JVM target inconsistency for legacy packages.
        val javaExt = extensions.findByType(JavaPluginExtension::class.java)
        if (javaExt != null) {
            javaExt.sourceCompatibility = JavaVersion.VERSION_17
            javaExt.targetCompatibility = JavaVersion.VERSION_17
        }

        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = "17"
            targetCompatibility = "17"
        }
    }

    val configureNamespace = Action<Project> {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val getNamespace = androidExt.javaClass.methods.firstOrNull { it.name == "getNamespace" }
                val setNamespace = androidExt.javaClass.methods.firstOrNull { it.name == "setNamespace" && it.parameterTypes.size == 1 && it.parameterTypes[0] == String::class.java }
                if (getNamespace != null && setNamespace != null) {
                    val current = getNamespace.invoke(androidExt) as String?
                    if (current.isNullOrEmpty()) {
                        var pkg: String? = null
                        val manifestFile = project.file("src/main/AndroidManifest.xml")
                        if (manifestFile.exists()) {
                            val manifestText = manifestFile.readText()
                            val match = Regex("package=\"([^\"]+)\"").find(manifestText)
                            if (match != null) {
                                pkg = match.groupValues[1]
                            }
                        }
                        val ns = pkg ?: "com.example.${project.name.replace(Regex("[^a-zA-Z0-9_]"), "_")}"
                        setNamespace.invoke(androidExt, ns)
                    }
                }
            } catch (e: Exception) {
                // Ignore reflection exceptions
            }
        }
    }

    if (state.executed) {
        configureNamespace.execute(this)
    } else {
        afterEvaluate {
            configureNamespace.execute(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

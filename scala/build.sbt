val scala3Version = "3.5.1"

lazy val root = project
  .in(file("."))
  .settings(
    name := "life",
    version := "0.1.0-SNAPSHOT",
    scalaVersion := scala3Version,
    libraryDependencies += "com.novocode" % "junit-interface" % "0.11" % "test"
  )

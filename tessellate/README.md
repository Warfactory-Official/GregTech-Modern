# Tessellate patch set: GregTechCEu/GregTech-Modern
- Base: `eb0fb0cd49c592929e8dee83f34f7c6ac566e8d7` (1.21 branch eb0fb0cd49 (srv-final base))
- Patches (apply in order): `0001-pipenet-thread-safety.patch` `0002-multiblock-saveddata-levelmixin.patch` `0003-machine-tick-subscriptions.patch` `0004-saveddata-vein-hazard.patch` 
- Apply: `bash tessellate/apply.sh <checkout at base>` = `git apply --3way` each, fail hard
- Build: `sh ./gradlew jar -x test --no-daemon` (JDK 21); `tessellate/finalize.py` appends "Patched for Tessellate async region ticking." to description, jar -> `<name>-tessellate.jar`; modId/version untouched
- Maven: `com.wf.tessellate:gtceu-tessellate:<modVersion>-SNAPSHOT` @ https://repo.warfactory.co/snapshots (secrets WARFACTORY_MAVEN_USER/TOKEN)
- CI: `.github/workflows/tessellate-patched.yml`

#!/usr/bin/env bash
# publish.sh OUTDIR GROUP ARTIFACT: PUT jar+pom to Warfactory snapshots in Gradle's unique-snapshot layout.
# Content Director (MavenRepository.resolve) needs: <artifact>/maven-metadata.xml, <ver>-SNAPSHOT/maven-metadata.xml, a checksum beside the jar.
set -euo pipefail
OUT=$1 GROUP=$2 ART=$3
. "$OUT/coords.env"
if [ -z "${WARFACTORY_MAVEN_USER:-}" ] || [ -z "${WARFACTORY_MAVEN_TOKEN:-}" ]; then
  echo "::notice::WARFACTORY_MAVEN_USER/WARFACTORY_MAVEN_TOKEN unset: publish skipped, jar only uploaded as workflow artifact"
  exit 0
fi
REPO=https://repo.warfactory.co/snapshots
V="${MOD_VERSION}-SNAPSHOT"
ABASE="$REPO/${GROUP//.//}/$ART"
VBASE="$ABASE/$V"
auth=(-u "$WARFACTORY_MAVEN_USER:$WARFACTORY_MAVEN_TOKEN")

prev=$(curl -fsS "${auth[@]}" "$VBASE/maven-metadata.xml" 2>/dev/null | sed -n 's:.*<buildNumber>\([0-9]*\)</buildNumber>.*:\1:p' | head -1 || true)
N=$(( ${prev:-0} + 1 ))
TS=$(date -u +%Y%m%d.%H%M%S)
UPD=${TS/./}
FV="${MOD_VERSION}-${TS}-${N}"

cat > "$OUT/$ART-$FV.pom" <<POM
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"><modelVersion>4.0.0</modelVersion>
<groupId>$GROUP</groupId><artifactId>$ART</artifactId><version>$V</version><packaging>jar</packaging></project>
POM
cat > "$OUT/vmeta.xml" <<META
<?xml version="1.0" encoding="UTF-8"?>
<metadata modelVersion="1.1.0">
  <groupId>$GROUP</groupId>
  <artifactId>$ART</artifactId>
  <versioning>
    <lastUpdated>$UPD</lastUpdated>
    <snapshot>
      <timestamp>$TS</timestamp>
      <buildNumber>$N</buildNumber>
    </snapshot>
    <snapshotVersions>
      <snapshotVersion><extension>jar</extension><value>$FV</value><updated>$UPD</updated></snapshotVersion>
      <snapshotVersion><extension>pom</extension><value>$FV</value><updated>$UPD</updated></snapshotVersion>
    </snapshotVersions>
  </versioning>
  <version>$V</version>
</metadata>
META
others=$(curl -fsS "${auth[@]}" "$ABASE/maven-metadata.xml" 2>/dev/null | sed -n 's:.*<version>\([^<]*\)</version>.*:\1:p' | grep -vxF "$V" || true)
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo "<metadata><groupId>$GROUP</groupId><artifactId>$ART</artifactId><versioning><latest>$V</latest><versions>"
  for v in $others $V; do echo "<version>$v</version>"; done
  echo "</versions><lastUpdated>$UPD</lastUpdated></versioning></metadata>"
} > "$OUT/ameta.xml"

put() {
  curl -fsS --retry 3 "${auth[@]}" -X PUT --upload-file "$1" "$2" >/dev/null
  for a in md5 sha1 sha256 sha512; do
    "${a}sum" "$1" | cut -d' ' -f1 > "$1.$a"
    curl -fsS --retry 3 "${auth[@]}" -X PUT --upload-file "$1.$a" "$2.$a" >/dev/null
  done
}
put "$OUT/$OUT_JAR" "$VBASE/$ART-$FV.jar"
put "$OUT/$ART-$FV.pom" "$VBASE/$ART-$FV.pom"
put "$OUT/vmeta.xml" "$VBASE/maven-metadata.xml"
put "$OUT/ameta.xml" "$ABASE/maven-metadata.xml"
echo "published $GROUP:$ART:$FV"

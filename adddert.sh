#!/bin/bash

set -e

CERT_FILE="$1"
ALIAS="$2"
PASSWORD="changeit"

# check arguments
if [ ! -f "$CERT_FILE" ]; then
  echo "'$CERT_FILE' not found"
  exit 1
fi

if [ -z "$ALIAS" ]; then
  echo "Specify alias"
  exit 1
fi

# Automatically find java machines
JAVA_HOMES=()

# Find installed java home
if command -v /usr/libexec/java_home &> /dev/null; then
  JAVA_HOMES=( $(/usr/libexec/java_home -V 2>&1 | grep -E '\/Contents\/Home' | tr -d ',' | xargs) )
fi

# Linux: finding possible paths
if [ -d "/usr/lib/jvm" ]; then
  JAVA_HOMES+=( $(find /usr/lib/jvm -type d -name "*jre*" -o -name "*jdk*" | xargs) )
fi

# Additionale: checking /opt
if [ -d "/opt" ]; then
  JAVA_HOMES+=( $(find /opt -type d -name "*jre*" -o -name "*jdk*" | xargs) )
fi

# Unique path
JAVA_HOMES=$(printf '%s\n' "${JAVA_HOMES[@]}" | sort -u)

# Chek if any JVM  exists
if [ ${#JAVA_HOMES[@]} -eq 0 ]; then
  echo "Error: no jvm's found"
  exit 1
fi

# add cert for each found JVM
SUCCESS=0

for JAVA_HOME in "${JAVA_HOMES[@]}"; do
  KEYSTORE="$JAVA_HOME/lib/security/cacerts"
  if [ -f "$KEYSTORE" ]; then
    echo "Addding cert to $JAVA_HOME"
    KEYTOOL="$JAVA_HOME/bin/keytool"
    if "$KEYTOOL" -import -trustcacerts -alias "$ALIAS" -file "$CERT_FILE" -keystore "$KEYSTORE" -storepass "$PASSWORD" -noprompt; then
      echo "Successfully added to $JAVA_HOME"
      SUCCESS=$((SUCCESS + 1))
    else
      echo "Error: unable to add $JAVA_HOME"
    fi
  else
    echo "Warning: cacerts not found $JAVA_HOME — skipped."
  fi
done

if [ "$SUCCESS" -gt 0 ]; then
  echo "Done: cert Successfully added to $SUCCESS truststore"
  exit 0
else
  echo "Error: unable to add cert in any truststore"
  exit 1
fi



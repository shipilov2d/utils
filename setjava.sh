#java setup
setjava() {
        unset JAVA_HOME
        export JAVA_HOME=$(/usr/libexec/java_home -v $1)
}

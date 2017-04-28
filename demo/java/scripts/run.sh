#!/bin/sh

JAVA_OPTS=" -server -Xmx2048M -Xms2048M  -XX:MaxMetaspaceSize=256M -Xss256K -XX:+PrintClassHistogram -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintHeapAtGC -Xloggc:./gc.log  -Djava.awt.headless=true "
#-Djava.awt.headless=true -Dcom.sun.management.jmxremote.port=1099 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false
#echo "pwd: "`pwd` ${project.artifactId}
#echo "scriptPath1: "$(cd `dirname $0`; pwd)
#echo "scriptPath2: "$(pwd)
#echo "scriptPath4: "$(cd $(dirname ${BASH_SOURCE:-$0});pwd)
echo --------
DIRNAME=$(pwd)
FILENAME=`basename $0 .jar`
PATHNAME=OneAPM-${FILENAME}
rm -fr ${PATHNAME}
 unzip -o $0 "OneAPM/*" -d  ${PATHNAME}
echo unzip -o $0 "OneAPM/*" -d ${0} ${@}
 exec java -javaagent:${DIRNAME}/${PATHNAME}/OneAPM/oneapm.jar ${JAVA_OPTS} -jar $0 "$@"
#exec java ${JAVA_OPTS} -jar $0 "$@"
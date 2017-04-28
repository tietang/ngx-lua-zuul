#!/bin/bash
#
#    .   ____          _            __ _ _
#   /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
#  ( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
#   \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
#    '  |____| .__|_| |_|_| |_\__, | / / / /
#   =========|_|==============|___/=/_/_/_/
#   :: Spring Boot Startup Script ::
#

### BEGIN INIT INFO
# Provides:          {{initInfoProvides:spring-boot-application}}
# Required-Start:    $remote_fs $syslog $network
# Required-Stop:     $remote_fs $syslog $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: {{initInfoShortDescription:Spring Boot Application}}
# Description:       {{initInfoDescription:Spring Boot Application}}
# chkconfig:         {{initInfoChkconfig:2345 99 01}}
### END INIT INFO

[[ -n "$DEBUG" ]] && set -x

#---  start

FILENAME=`basename $0 .jar`

PID_FOLDER="./RUN_${FILENAME}"
LOG_FOLDER="./LOGS_${FILENAME}"

ONEAPM_PATHNAME=OneAPM-${FILENAME}
CURR=`date +%Y%m%d`
[[ -z "$JAVA_OPTS" ]] && JAVA_OPTS=" -server -Xmx2048M -Xms2048M  -XX:MaxMetaspaceSize=128M -Xss256K -XX:+PrintClassHistogram -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintHeapAtGC -Xloggc:./GC_${FILENAME}_${CURR}.log  -Djava.awt.headless=true "

[[ -z "$FORCE_UNZIP_ONEAPM" ]] && FORCE_UNZIP_ONEAPM="true"

un_zip(){
#    if [ $FORCE_UNZIP_ONEAPM = "true" ] || [ ! -d ${ONEAPM_PATHNAME} ] ; then
#        rm -fr ${ONEAPM_PATHNAME}
#        unzip -o $0 "BOOT-INF/classes/OneAPM/*" -d  ${ONEAPM_PATHNAME}
#        mv ./${ONEAPM_PATHNAME}/BOOT-INF/classes/OneAPM ./${ONEAPM_PATHNAME}/OneAPM
#        rm -r ${ONEAPM_PATHNAME}/BOOT-INF/
#    fi
    echo "nothing"
}

#---- end

# Initialize variables that cannot be provided by a .conf file
WORKING_DIR="$(pwd)"
# shellcheck disable=SC2153
[[ -n "$JARFILE" ]] && jarfile="$JARFILE"
[[ -n "$APP_NAME" ]] && identity="$APP_NAME"

# Follow symlinks to find the real jar and detect init.d script
cd "$(dirname "$0")" || exit 1
[[ -z "$jarfile" ]] && jarfile=$(pwd)/$(basename "$0")
while [[ -L "$jarfile" ]]; do
  [[ "$jarfile" =~ init\.d ]] && init_script=$(basename "$jarfile")
  jarfile=$(readlink "$jarfile")
  cd "$(dirname "$jarfile")" || exit 1
  jarfile=$(pwd)/$(basename "$jarfile")
done
jarfolder="$(dirname "$jarfile")"
cd "$WORKING_DIR" || exit 1

# Source any config file
configfile="$(basename "${jarfile%.*}.conf")"
# shellcheck source=/dev/null
[[ -r "${jarfolder}/${configfile}" ]] && source "${jarfolder}/${configfile}"

# Initialize PID/LOG locations if they weren't provided by the config file
[[ -z "$PID_FOLDER" ]] && PID_FOLDER="/var/run"
[[ -z "$LOG_FOLDER" ]] && LOG_FOLDER="/var/log"
! [[ -x "$PID_FOLDER" ]] && PID_FOLDER="/tmp"
! [[ -x "$LOG_FOLDER" ]] && LOG_FOLDER="/tmp"

# Set up defaults
[[ -z "$MODE" ]] && MODE="{{mode:auto}}" # modes are "auto", "service" or "run"
[[ -z "$USE_START_STOP_DAEMON" ]] && USE_START_STOP_DAEMON="{{useStartStopDaemon:true}}"

# Create an identity for log/pid files
if [[ -z "$identity" ]]; then
  if [[ -n "$init_script" ]]; then
    identity="${init_script}"
  else
    identity=$(basename "${jarfile%.*}")_${jarfolder//\//}
  fi
fi

# Initialize log file name if not provided by the config file
[[ -z "$LOG_FILENAME" ]] && LOG_FILENAME="${identity}.log"


# ANSI Colors
echoRed() { echo $'\e[0;31m'"$1"$'\e[0m'; }
echoGreen() { echo $'\e[0;32m'"$1"$'\e[0m'; }
echoYellow() { echo $'\e[0;33m'"$1"$'\e[0m'; }

# Utility functions
checkPermissions() {
  touch "$pid_file" &> /dev/null || { echoRed "Operation not permitted (cannot access pid file)"; return 4; }
  touch "$log_file" &> /dev/null || { echoRed "Operation not permitted (cannot access log file)"; return 4; }
}

isRunning() {
  ps -p "$1" &> /dev/null
}

await_file() {
  end=$(date +%s)
  let "end+=10"
  while [[ ! -s "$1" ]]
  do
    now=$(date +%s)
    if [[ $now -ge $end ]]; then
      break
    fi
    sleep 1
  done
}

# Determine the script mode
action="run"
if [[ "$MODE" == "auto" && -n "$init_script" ]] || [[ "$MODE" == "service" ]]; then
  action="$1"
  shift
fi

# Build the pid and log filenames
if [[ "$identity" == "$init_script" ]] || [[ "$identity" == "$APP_NAME" ]]; then
  PID_FOLDER="$PID_FOLDER/${identity}"
fi
pid_file="$PID_FOLDER/${identity}.pid"
log_file="$LOG_FOLDER/$LOG_FILENAME"

# Determine the user to run as if we are root
# shellcheck disable=SC2012
[[ $(id -u) == "0" ]] && run_user=$(ls -ld "$jarfile" | awk '{print $3}')

# Find Java
if [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]]; then
    javaexe="$JAVA_HOME/bin/java"
elif type -p java > /dev/null 2>&1; then
    javaexe=$(type -p java)
elif [[ -x "/usr/bin/java" ]];  then
    javaexe="/usr/bin/java"
else
    echo "Unable to find Java"
    exit 1
fi


# Build actual command to execute
command="$javaexe -Dsun.misc.URLClassPath.disableJarChecking=true $JAVA_OPTS -jar $jarfile $RUN_ARGS $*"
#command="$javaexe -javaagent:${WORKING_DIR}/${ONEAPM_PATHNAME}/OneAPM/oneapm.jar -Dsun.misc.URLClassPath.disableJarChecking=true $JAVA_OPTS -jar $jarfile $RUN_ARGS $*"
# exec java -javaagent:${DIRNAME}/${PATHNAME}/OneAPM/oneapm.jar ${JAVA_OPTS} -jar $0 "$@"


# Action functions
start() {
  if [[ -f "$pid_file" ]]; then
    pid=$(cat "$pid_file")
    isRunning "$pid" && { echoYellow "Already running [$pid]"; return 0; }
  fi
  do_start "$@"
}

do_start() {
  un_zip
  working_dir=$(dirname "$jarfile")
  pushd "$working_dir" > /dev/null
  if [[ -n "$run_user" ]]; then
    mkdir "$PID_FOLDER" &> /dev/null
    checkPermissions || return $?
    chown "$run_user" "$PID_FOLDER"
    chown "$run_user" "$pid_file"
    chown "$run_user" "$log_file"
    if [ $USE_START_STOP_DAEMON = true ] && type start-stop-daemon > /dev/null 2>&1; then
      arguments=(-Dsun.misc.URLClassPath.disableJarChecking=true $JAVA_OPTS -jar $jarfile $RUN_ARGS "$@")
      start-stop-daemon --start --quiet \
        --chuid "$run_user" \
        --name "$identity" \
        --make-pidfile --pidfile "$pid_file" \
        --background --no-close \
        --startas "$javaexe" \
        --chdir "$working_dir" \
        -- "${arguments[@]}" \
        >> "$log_file" 2>&1
      await_file "$pid_file"
    else
#      su -s /bin/sh -c "$command >> \"$log_file\" 2>&1 & echo \$!" "$run_user" > "$pid_file"
      "$command >> \"$log_file\" 2>&1 & echo \$!" "$run_user" > "$pid_file"
    fi
    pid=$(cat "$pid_file")
  else
    checkPermissions || return $?
    $command >> "$log_file" 2>&1 &
    pid=$!
    disown $pid
    echo "$pid" > "$pid_file"
  fi
  [[ -z $pid ]] && { echoRed "Failed to start"; return 1; }
  echoGreen "Started [$pid]"
}

stop() {
  [[ -f $pid_file ]] || { echoYellow "Not running (pidfile not found)"; return 0; }
  pid=$(cat "$pid_file")
  isRunning "$pid" || { echoYellow "Not running (process ${pid}). Removing stale pid file."; rm -f "$pid_file"; return 0; }
  do_stop "$pid" "$pid_file"
}

do_stop() {
  kill "$1" &> /dev/null || { echoRed "Unable to kill process $1"; return 1; }
  for i in $(seq 1 60); do
    isRunning "$1" || { echoGreen "Stopped [$1]"; rm -f "$2"; return 0; }
    [[ $i -eq 30 ]] && kill "$1" &> /dev/null
    sleep 1
  done
  echoRed "Unable to kill process $1";
  return 1;
}

restart() {
  stop && start
}

force_reload() {
  [[ -f $pid_file ]] || { echoRed "Not running (pidfile not found)"; return 7; }
  pid=$(cat "$pid_file")
  rm -f "$pid_file"
  isRunning "$pid" || { echoRed "Not running (process ${pid} not found)"; return 7; }
  do_stop "$pid" "$pid_file"
  do_start
}

status() {
  [[ -f "$pid_file" ]] || { echoRed "Not running"; return 3; }
  pid=$(cat "$pid_file")
  isRunning "$pid" || { echoRed "Not running (process ${pid} not found)"; return 1; }
  echoGreen "Running [$pid]"
  return 0
}

run() {
  un_zip

  pushd "$(dirname "$jarfile")" > /dev/null
  echo $command
  exec $command

  result=$?
  popd
  return "$result"
}

run2() {
  if [[ -f "$pid_file" ]]; then
    pid=$(cat "$pid_file")
    isRunning "$pid" && { echoYellow "Already running [$pid]"; return 0; }
  fi
  do_run "$@"
}

do_run() {
  un_zip
  working_dir=$(dirname "$jarfile")
  pushd "$working_dir" > /dev/null
    mkdir "$PID_FOLDER" &> /dev/null
    checkPermissions || return $?
    chown "$run_user" "$PID_FOLDER"
    chown "$run_user" "$pid_file"
    chown "$run_user" "$log_file"

#      su -s /bin/sh -c "$command >> \"$log_file\" 2>&1 & echo \$!" "$run_user" > "$pid_file"
#   "$command & echo \$!" "$run_user" > "$pid_file"
    echo $command
    $command
#    pid=$(cat "$pid_file")

    pid=$!
    disown $pid
    echo "$pid" > "$pid_file"

  [[ -z $pid ]] && { echoRed "Failed to start"; return 1; }
  echoGreen "Started [$pid]"
}

# Call the appropriate action function
case "$action" in
start)
  start "$@"; exit $?;;
stop)
  stop "$@"; exit $?;;
restart)
  restart "$@"; exit $?;;
force-reload)
  force_reload "$@"; exit $?;;
status)
  status "$@"; exit $?;;
run)
  run "$@"; exit $?;;
*)
  echo "Usage: $0 {start|stop|restart|force-reload|status|run}"; exit 1;
esac

exit 0
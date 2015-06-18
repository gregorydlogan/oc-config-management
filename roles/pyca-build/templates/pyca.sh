#!/bin/sh
#
# pyca         Start/Stop the Python Opencast Matterhorn Capture Agent
#
# chkconfig:   - 60 40
# description: PyCA is a fully functional Opencast Matterhorn capture agent \
#              written in Python. It is free software licenced under the \
#              terms of the GNU Lesser General Public License.

### BEGIN INIT INFO
# Provides: pyca
# Required-Start: $local_fs $remote_fs $syslog $network
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: run pyca
# Description: PyCA is a fully functional Opencast Matterhorn capture agent
#              written in Python. It is free software licenced under the terms
#              of the GNU Lesser General Public : License.
### END INIT INFO

# Documentation available at
# http://refspecs.linuxfoundation.org/LSB_3.1.0/LSB-Core-generic/LSB-Core-generic/iniscrptfunc.html
# Debian provides some extra functions though
. /lib/lsb/init-functions


DAEMON_NAME="pyca"
DAEMON_USER="{{matterhorn_user}}"
DAEMON_PATH="{{pyca_base_dir}}/start.sh"
DAEMON_OPTS=""
DAEMON_PWD="${PWD}"
DAEMON_DESC=$(get_lsb_header_val $0 "Short-Description")
DAEMON_PID="/var/run/${DAEMON_NAME}.pid"
DAEMON_NICE=0
DAEMON_LOG='{{pyca_log_dir}}/pyca.log'

[ -r "/etc/default/${DAEMON_NAME}" ] && . "/etc/default/${DAEMON_NAME}"

do_start() {
  local result

	pidofproc -p "${DAEMON_PID}" "${DAEMON_PATH}" > /dev/null
	if [ $? -eq 0 ]; then
		log_warning_msg "${DAEMON_NAME} is already started"
		result=0
	else
		log_daemon_msg "Starting ${DAEMON_DESC}" "${DAEMON_NAME}"
		touch "${DAEMON_LOG}"
		chown $DAEMON_USER "${DAEMON_LOG}"
		chmod u+rw "${DAEMON_LOG}"
		export PYTHONPATH={{pyca_base_dir}}
		if [ -z "${DAEMON_USER}" ]; then
			start-stop-daemon --start --oknodo --background \
				--nicelevel $DAEMON_NICE \
				--chdir "${DAEMON_PWD}" \
				--pidfile "${DAEMON_PID}" --make-pidfile \
				--startas /bin/bash -- \
				-c "exec python -m pyca.__main__ > ${DAEMON_LOG} 2>&1" -- $DAEMON_OPTS
			result=$?
		else
			start-stop-daemon --start --oknodo --background \
				--nicelevel $DAEMON_NICE \
				--chdir "${DAEMON_PWD}" \
				--pidfile "${DAEMON_PID}" --make-pidfile \
				--chuid "${DAEMON_USER}" \
				--startas /bin/bash -- \
				-c "exec python -m pyca.__main__ > ${DAEMON_LOG} 2>&1" -- $DAEMON_OPTS
			result=$?
		fi
		log_end_msg $result
	fi
	return $result
}

do_stop() {
	local result

	pidofproc -p "${DAEMON_PID}" "${DAEMON_PATH}" > /dev/null
	if [ $? -ne 0 ]; then
		log_warning_msg "${DAEMON_NAME} is not started"
		result=0
	else
		log_daemon_msg "Stopping ${DAEMON_DESC}" "${DAEMON_NAME}"
		killproc -p "${DAEMON_PID}" "${DAEMON_PATH}"
		result=$?
		log_end_msg $result
		rm "${DAEMON_PID}"
	fi
	return $result
}

do_restart() {
	local result
	do_stop
	result=$?
	if [ $result = 0 ]; then
		do_start
		result=$?
	fi
	return $result
}

do_status() {
	local result
	status_of_proc -p "${DAEMON_PID}" "${DAEMON_PATH}" "${DAEMON_NAME}"
	result=$?
	return $result
}

do_usage() {
	echo $"Usage: $0 {start | stop | restart | status}"
	exit 1
}

case "$1" in
start)   do_start;   exit $? ;;
stop)    do_stop;    exit $? ;;
restart) do_restart; exit $? ;;
status)  do_status;  exit $? ;;
*)       do_usage;   exit  1 ;;
esac

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
# Default-Start:
# Default-Stop:
# Short-Description: run pyca
# Description: PyCA is a fully functional Opencast Matterhorn capture agent
#              written in Python. It is free software licenced under the terms
#              of the GNU Lesser General Public : License.
### END INIT INFO

pyca="{{pyca_base_dir}}/start.sh"
prog="pyca"
logfile={{pyca_log_dir}}/pyca.log
lockfile=/var/lock/subsys/pyca
[ -d "/var/lock/subsys" ] || lockfile="/var/lock/LCK.${prog}"
pidfile="/var/run/${prog}.pid"

killdelay=7

# Load configuration files
[ -e /etc/sysconfig/$prog ] && . /etc/sysconfig/$prog

success() {
	printf "\r%-58s [\033[32m  OK  \033[0m]\n" "$1"
}

failed() {
	printf "\r%-58s [\033[31mFAILED\033[0m]\n" "$1"
}

start() {
	smsg="Starting $prog: "
	echo -n $smsg

	# Start pyca and create a lockfile
	( flock -n 9 && $pyca > $logfile & ) 9> $lockfile
	retval=$?

	# If we failed with retval=1 pyca might be already up and running. In
	# that case we still want to return a success:
	[ $retval -eq 1 ] && rh_status_q && echo && exit 1

	# If we failed to start pyca but a lock was created, we want to remove
	# the file (flock does not remove the file automatically):
	[ ! $retval -eq 0 ] && rm -f $lockfile

	[ $retval -eq 0 ] && success "$smsg" || failed "$smsg"
	return $retval
}

stop() {
	smsg="Stopping $prog: "
	echo -n $smsg
    [ -f $lockfile ] || ( failed "$smsg"; return 1 )

    pretval=$?
	if [ $retval -eq 0 ]
	then
		rm -f $lockfile
		success "$smsg"
	else
		failed "$smsg"
	fi
	return $retval
}

restart() {
	stop
	start
}

reload() {
	restart
}

force_reload() {
	restart
}

rh_status() {
	# run checks to determine if the service is running or use generic status
	if [ -f $lockfile ] && [ -f $pidfile ]
	then
		pid="$(cat $pidfile)"
		ps p $pid &> /dev/null && echo $"${prog} (pid $pid) is running..." && return 0
		echo $"${prog} dead but pid file exists"
		return 1
	fi
	[ -f $pidfile ] && echo "pidfile exists but subsys not locked" && return 4
	[ -f $lockfile ] && echo "${prog} dead but subsys locked" && return 2
	echo "${prog} is stopped"
	return 3
}

rh_status_q() {
	rh_status >/dev/null 2>&1
}


case "$1" in
	start)
		rh_status_q && exit 0
		$1
		;;
	stop)
		rh_status_q || exit 0
		$1
		;;
	restart)
		$1
		;;
	reload)
		rh_status_q || exit 7
		$1
		;;
	force-reload)
		force_reload
		;;
	status)
		rh_status
		;;
	condrestart|try-restart)
		rh_status_q || exit 0
		restart
		;;
	*)
		echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload}"
		exit 2
esac
exit $?

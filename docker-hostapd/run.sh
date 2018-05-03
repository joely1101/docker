
INF=$1
[ "$INF" = "" ] && echo "please assigned interfacr for hostapd" && exit
echo "building image"
docker build -t hostapd-wire . 
[ "$?" != "0" ] && echo "build image fail" && exit
echo "running hostapd in docker"
docker run -it --rm --net=host -e INTERFACE=$INF --privileged hostapd-wire sh /data/run_hostapd.sh

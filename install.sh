#!/bin/sh

VER="1.0.3"
target_dir="${TARGET_DIR}"
mkdir -p $(dirname $LOG)
echo "begin to install smb FlexVolume driver ${VER} ..." 

if [[ -z "${target_dir}" ]]; then
  target_dir="/etc/kubernetes/kubelet-plugins/volume/exec"
fi

smb_vol_dir="${target_dir}/microsoft.com~smb"
mkdir -p ${smb_vol_dir}

if [ "$INSTALL_DEPS" = true ] ; then
  echo "installing statically linked dependencies (jq, cifs-utils)" 
  # copy any other static deps
  cp ${SOURCE_DIR}/* ${smb_vol_dir}
else
  echo "skipping installing deps: jq and cifs-utils must be pre-installed" 
fi

#copy smb script
cp /bin/smb ${smb_vol_dir}/smb
chmod a+x ${smb_vol_dir}/smb

echo "install smb FlexVolume driver completed."

#https://github.com/kubernetes/kubernetes/issues/17182
# if we are running on kubernetes cluster as a daemon set we should
# not exit otherwise, container will restart and goes into crashloop (even if exit code is 0)
echo "install done, daemonset sleeping"
while true; do 
    sleep 3600
done

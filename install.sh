#!/bin/sh

VER="1.0.3"
vendor=${VENDOR-bertera.it}
target_dir="${TARGET_DIR-/etc/kubernetes/kubelet-plugins/volume/exec}"

function bailout {
    echo ERROR: $@
    exit 1
}

echo "begin to install smb FlexVolume driver ${VER} ..." 

#if [[ -z "${target_dir}" ]]; then
#  target_dir="/etc/kubernetes/kubelet-plugins/volume/exec"
#fi

smb_vol_dir="${target_dir}/${vendor}~smb"
mkdir -p ${smb_vol_dir} || bailout creating plugin directory ${smb_vol_dir}

if [ "$INSTALL_DEPS" = true ] ; then
  echo "installing statically linked dependencies (jq, cifs-utils)" 
  # copy any other static deps
  cp ${SOURCE_DIR}/* ${smb_vol_dir} || bailout installing deps
else
  echo "skipping installing deps: jq and cifs-utils must be pre-installed" 
fi

#copy smb script
cp /bin/smb ${smb_vol_dir}/smb || bailout installing the plugin
chmod a+x ${smb_vol_dir}/smb || bailout setting the permissions

echo "install smb FlexVolume driver completed."

while true; do 
    sleep 3600
done

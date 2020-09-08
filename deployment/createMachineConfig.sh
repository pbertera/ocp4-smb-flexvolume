#!/bin/sh

driver="$(dirname "$(readlink -f "$0")")/../driver/smb"
vendor="${1-bertera.it}"
target_dir="${2-/etc/kubernetes/kubelet-plugins/volume/exec}"
role="${3-worker}"

smb_vol_dir="${target_dir}/${vendor}~smb"

cat <<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  labels:
    machineconfiguration.openshift.io/role: $role
  name: 50-smb-flexvolume-driver
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
      - contents:
          source: data:text/plain;charset=utf-8;base64,$(cat "$driver" | base64 -w0)
        filesystem: root
        mode: 0755
        path: ${smb_vol_dir}/smb
EOF

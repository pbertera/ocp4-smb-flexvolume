# OpenShift 4.x SMB FlexVolume plugin PoC

This repo contains a proof of concepf of SMB/CIFS [Kubernetes FlexVolume](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-storage/flexvolume.md) driver deployable on OpenShift 4.x.

This driver takes inspiration from the original Microsoft k8s [driver](https://github.com/Azure/kubernetes-volume-drivers/tree/master/flexvolume/smb) with some customizations specific for a k8s based on OpenShift 4.x and Red Hat CoreOS.

The driver must be deployed on all nodes running a workload requiring an SMB/CIFS volume.
You can follow two deployment types: using a `DaemonSet` or a `MachineConfig` node customisation.

## Deployment with Machine Config Operator

Leveraging the `MachineConfig` operator the driver is added to the nodes.

### Nodes requirements

- This procedure do not install the `mount.cifs` binary on CoreOS nodes but relies on the Kernel CIFS support using the `mount -t cifs` (enabled by default on CoreOS nodes).
- The driver requires the `jq` binary too (by default already installed on CoreOS nodes).

### Procedure

0. clone the git repo: 
```
$ git clone https://github.com/pbertera/ocp4-smb-flexvolume.git
$ cd ocp4-smb-flexvolume
```

1. [OPTIONAL] create a custom `MachineConfigPool` for the nodes where the diver will be installed
```
$ cat smb-mcp.yaml
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfigPool
metadata:
  name: smb-worker
spec:
  machineConfigSelector:
    matchExpressions:
      - {key: machineconfiguration.openshift.io/role, operator: In, values: [worker, smb-worker]}
  nodeSelector:
    matchLabels:
      node-role.kubernetes.io/smb-worker: ""
  paused: false
$ oc apply -f smb-mcp.yaml
```

2. create the `MachineConfig`: the script `./deployment/createMachineConfig.sh` creates the `MachineConfig` you can customize the vendor specifying your vendor as first parameter of the command.
```
$ ./deployment/createMachineConfig.sh > smb-mc.yaml 
# IF YOU WANT TO USE A CUSTOM MCP SET THE PROPER LABEL INTO smb-mc.yaml
$ oc apply -f smb-mc.yaml
```

3. [OPTIONAL] if you crated a dedicated MCP, add one or more nodes to the MCP

4. monitor the MCP
```
$ oc describe mcp smb-workers
```

5. once the MCP is ready and all the nodes are updated the driver is installed. You can check it with:
```
# the below command should list the smb executable
oc debug node/<node-name> -- chroot /host ls -l /etc/kubernetes/kubelet-plugins/volume/exec/bertera.it~smb/
```

## Deployment with a DeamonSet

Even if this is not a good idea on OpenShift, this is one of the most common FlexVolume driver deployment procedure on k8s.

With this deployment a pod is executed on every node where the driver is needed.
When the pod starts the driver is copied into the node, after that the pod is idling all the time.

The pod requires a `RW` access to the host directory specified by the kubelet option `--volume-plugin-dir`. For that reason the pods must run as `root` and must be able to mount `hostPath` volumes.

**IMPORTANT SECURITY NODE:** Running priviledged pods can be a security risk, if you want to follow this procedure be aware of that and limit the nodes with a proper nodeSelector.

```
$ cd deployment
$ oc apply -f rbac.yaml
$ oc apply -f ds.yaml
```

## Usage

1. create a secret with same type of the vendor name you used to deploy the driver:
```
$ oc create secret generic smbcreds --from-literal username=$SMBUSER --from-literal password=$SMBPASS --type bertera.it/smb
```

Optionally you can pass the `domain` key to the secret to define the SMB domain to use.

2. deploy a workload using the `flexVolume` driver
```
$ cat << EOF | oc apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-flex-smb
spec:
  containers:
    - name: nginx-flex-smb
      image: nginx
      volumeMounts:
        - name: test
          mountPath: /data
  volumes:
    - name: test
      flexVolume:
        driver: "bertera.it/smb"
        secretRef:
          name: smbcreds # here is the name of the previously created secret
        options:
          source: "//172.30.182.189/share" # the share path
          mountoptions: "vers=1.0,uid=1000,gid=1000" # with mount options you can pass custom options
  nodeSelector:
    node-role.kubernetes.io/smb-worker: ""
EOF
```

## Troubleshooting

Actions performed by the driver are logged into `/var/log/smb-driver.log`. Logs can be viewed with:

```
$ oc adm node-logs --role worker --path=/smb-driver.log
```

Defining the secret key `debug` with value `true` will make the driver logging also the credentials in cleartext.

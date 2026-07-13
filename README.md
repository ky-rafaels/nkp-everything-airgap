# Purpose

The goal of this repo is to provide a standardized helm chart for the installation of NKP workload clusters in an airgapped environment on various infrastructure. This chart is designed to provide an production forward methodology for installing and managing NKP workload clusters at scale.

## Dependencies

- kubectl
- helm

## Installing the preprovisioned NKP cluster chart

The chart in [preprovisioned/nkp-2.17.1](preprovisioned/nkp-2.17.1) renders the Cluster API
resources (Cluster, KubeadmControlPlane, PreprovisionedInventory, MachineDeployment, addon
ClusterResourceSets, etc.) needed to stand up an NKP workload cluster on preprovisioned
(bare-metal/BYO) infrastructure. It's applied against a management cluster that already has
Cluster API and the Konvoy preprovisioned infrastructure provider installed.

1. Make sure your kubeconfig context points at the **management cluster**, not the workload
   cluster being created.

2. Create the target namespace if it doesn't already exist (defaults to `edge-clusters`):

   ```bash
   kubectl create namespace edge-clusters
   ```

3. Copy `preprovisioned/nkp-2.17.1/values.yaml` and customize it for your environment, at minimum:
   - `cluster.name` / `cluster.namespace`
   - `cluster.network.podCIDR` / `serviceCIDR`
   - `cluster.controlPlaneEndpoint` and `cluster.controlPlane.endpointHost`/`virtualIPInterface`
   - `cluster.controlPlane.hosts` and `cluster.workers.hosts` (SSH-reachable node addresses)
   - `cluster.ssh.user` and `cluster.ssh.privateKeyBase64` (base64-encoded private key used to
     reach every host - do not commit real key material)

4. (Optional) Render the chart locally to review the generated manifests before applying:

   ```bash
   helm template nkp-workload preprovisioned/nkp-2.17.1 -f my-values.yaml
   ```

5. Install the chart:

   ```bash
   helm install nkp-workload preprovisioned/nkp-2.17.1 \
     -f my-values.yaml \
     --namespace edge-clusters
   ```

   To pass the SSH private key without putting it in a values file, use `--set-file`:

   ```bash
   helm install nkp-workload preprovisioned/nkp-2.17.1 \
     -f my-values.yaml \
     --namespace edge-clusters \
     --set-file cluster.ssh.privateKeyBase64=<(base64 < /path/to/id_rsa)
   ```

6. Track cluster provisioning on the management cluster:

   ```bash
   kubectl get cluster,kubeadmcontrolplane,machinedeployment -n edge-clusters
   clusterctl describe cluster <cluster.name> -n edge-clusters
   ```

To apply changes later (e.g. after editing values or adding hosts), use `helm upgrade` with the
same release name and namespace:

```bash
helm upgrade nkp-workload preprovisioned/nkp-2.17.1 -f my-values.yaml --namespace edge-clusters
```

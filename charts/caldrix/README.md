# caldrix

The `caldrix` chart runs one `caldrix serve` of one model on Kubernetes, from the caldrix CPU image
(`ghcr.io/caldrix-ai/caldrix`). The server is OpenAI-compatible; see the
[caldrix docs](https://github.com/caldrix-ai/caldrix/blob/main/docs/serve.md).

## What it installs

With the defaults, `helm install` creates:

- one Deployment (one replica, `strategy: Recreate`) whose container runs
  `serve smollm2-instruct --host 0.0.0.0 --port 8425 --backend cpu`, as the image's non-root user (10001);
- one PersistentVolumeClaim (`ReadWriteOnce`, 20Gi, the cluster's default StorageClass) mounted at
  `/data/huggingface`, the model cache, so a restart does not download the model again;
- one ClusterIP Service on port 80 to the container's port 8425, named `http`;
- one ServiceAccount, with no RBAC: the server talks to no Kubernetes API;
- a `helm test` pod that curls `/healthz` and `/v1/models`.

The pod turns Ready only once the model is downloaded, compiled and loaded: the server binds its port after the
load. A startup probe allows 60 × 10 s for that.

## Install

```sh
helm install caldrix oci://ghcr.io/caldrix-ai/charts/caldrix --version 0.1.0 \
  --namespace caldrix --create-namespace
helm test caldrix --namespace caldrix
```

Then forward the Service and read the served model; the `id` it returns is the `model` to send:

```sh
kubectl --namespace caldrix port-forward svc/caldrix 8425:80
curl http://localhost:8425/v1/models
```

## Values

| key | default | meaning |
|---|---|---|
| `image.repository` | `ghcr.io/caldrix-ai/caldrix` | the caldrix image |
| `image.tag` | `""` | empty means `<appVersion>-cpu` |
| `image.digest` | `""` | a `sha256:…` digest; when set it wins over the tag, rendered `repository@sha256:…` |
| `image.pullPolicy` | `IfNotPresent` | |
| `image.gpu` | `false` | your plain statement that the image named above carries a GPU lane; the one switch the GPU rule reads |
| `imagePullSecrets` | `[]` | secrets for a private registry, as `[{name: <secret>}]` |
| `nameOverride` / `fullnameOverride` | `""` / `""` | replace the chart's name, or the whole name, in resource names |
| `model.name` | `smollm2-instruct` | the model: an alias, a hub id `owner/name[@revision]`, or `ollama:<tag>` |
| `model.context` | `""` | `--ctx N` when set; a positive integer |
| `model.backend` | `cpu` | `cpu` or `hip`; `hip` is refused unless `image.gpu` is true (the GPU rule) |
| `model.extraArgs` | `[]` | further `caldrix serve` arguments, appended verbatim |
| `huggingface.token` | `""` | a Hugging Face token inline, rendered into a Secret the chart owns |
| `huggingface.existingSecret` | `""` | an existing Secret holding the token; not with `huggingface.token` |
| `huggingface.existingSecretKey` | `HF_TOKEN` | the key in `huggingface.existingSecret` |
| `persistence.enabled` | `true` | a PersistentVolumeClaim for the model cache; `false` means an `emptyDir`, and every restart downloads the model again |
| `persistence.size` | `20Gi` | the claim's size |
| `persistence.storageClass` | `""` | empty means the cluster's default |
| `persistence.existingClaim` | `""` | an existing claim, mounted instead of creating one; refused with `persistence.enabled: false` |
| `persistence.accessModes` | `[ReadWriteOnce]` | the claim's access modes; with `existingClaim`, list that claim's modes, which the `replicaCount` rule reads |
| `volumePermissions.enabled` | `false` | a root initContainer that `chown`s the cache volume to `podSecurityContext.runAsUser`:`fsGroup` (`10001:10001` by default; see Storage) |
| `service.type` / `service.port` / `service.annotations` | `ClusterIP` / `80` / `{}` | the Service; its port maps to the container's 8425 |
| `ingress.enabled` | `false` | an Ingress to the Service |
| `ingress.className` / `ingress.annotations` | `""` / `{}` | the IngressClass, and annotations on the Ingress |
| `ingress.hosts[]` | `[]` | `[{host: <name>, paths: [{path: /, pathType: Prefix}]}]`; at least one host, each with at least one path, when `ingress.enabled` |
| `ingress.tls[]` | `[]` | `[{secretName: <secret>, hosts: [<name>]}]`, with your own certificates; each entry needs both |
| `networkPolicy.enabled` | `false` | a NetworkPolicy admitting ingress to port 8425 only; egress (the model download) is untouched |
| `networkPolicy.ingressFrom` | `[]` | the admitted peers, as NetworkPolicy `from` entries; `[]` admits any source |
| `tests.enabled` | `true` | the `helm test` pod; `false` renders none |
| `tests.image` | `curlimages/curl:8.17.0@sha256:935d…ff40` | the test pod's image, pinned by digest (the caldrix image has no `curl`); the one third-party image the chart names, used only by `helm test` |
| `resources` | requests `cpu: 2`, `memory: 4Gi`; no limits | the server sizes its thread pool from the CPU quota, so a CPU limit sets its thread count |
| `gpu.enabled` | `false` | request a GPU; refused unless `image.gpu` is true (the GPU rule) |
| `gpu.resource` / `gpu.count` | `amd.com/gpu` / `1` | the node resource requested, and how many |
| `gpu.runtimeClassName` | `""` | an optional RuntimeClass, with `gpu.enabled` |
| `probes.startup` | `failureThreshold: 60`, `periodSeconds: 10` | the download-and-compile allowance |
| `probes.readiness` / `probes.liveness` | `periodSeconds: 10` / `30` | `GET /healthz`; a probe's `httpGet` is merged over that one (its keys win) |
| `serviceAccount.create` / `name` / `annotations` | `true` / `""` / `{}` | the ServiceAccount; an empty name means the release's full name |
| `podSecurityContext` | `runAsUser: 10001`, `runAsNonRoot: true`, `fsGroup: 10001` | the pod's security context |
| `securityContext` | no privilege escalation, all capabilities dropped, `readOnlyRootFilesystem: false` | the container's; the root filesystem is kept writable (see Storage) |
| `env` | `[]` | extra environment variables, appended verbatim (`HF_ENDPOINT` for a mirror) |
| `extraVolumes` / `extraVolumeMounts` | `[]` / `[]` | extra volumes on the pod, and mounts in the container |
| `podAnnotations` / `podLabels` | `{}` / `{}` | on the pod |
| `priorityClassName` | `""` | the pod's PriorityClass |
| `nodeSelector` / `tolerations` / `affinity` | `{}` / `[]` / `{}` | the usual scheduling knobs |
| `replicaCount` | `1` | more than 1 needs `persistence.accessModes` with `ReadWriteMany`, or `persistence.enabled: false`; the render fails by name otherwise |

## The GPU rule

`gpu.enabled: true` or `model.backend: hip` renders only with `image.gpu: true`, your statement that the image you
named carries a GPU lane, because neither a tag nor a digest says anything about lanes. Otherwise `helm install` fails
with one sentence saying the ROCm image is not published yet; the default image is the CPU one.

## Storage

The pod's `fsGroup: 10001` makes a freshly provisioned volume writable by the server. Some provisioners ignore
`fsGroup`, hostPath and local-path among them; with those, set `volumePermissions.enabled: true`, which adds a root
initContainer that `chown`s the mount before the server starts.

The compiled kernels and the model-index copy are written under `/cache` (`XDG_CACHE_HOME`), an `emptyDir` with
`sizeLimit: 1Gi`; the root filesystem is kept writable.

## Exposure

The server has no authentication. The Service is ClusterIP; put a gateway that authenticates in front of it before
you expose it, through `ingress` or otherwise. `networkPolicy.enabled: true` admits traffic to port 8425 only, and
`networkPolicy.ingressFrom` narrows it to the peers you list, your gateway's among them; the `helm test` pod is
admitted only if it matches one of them.

## What the chart does not do

No auth, no rate limiting, no TLS of its own, no autoscaling (HPA): the server is single-process and stateful per
model. No PodDisruptionBudget, no NetworkPolicy unless `networkPolicy.enabled`, no CRDs, no operator, and no model
pre-pull job.

## Verified

Verified: installed with kind in a virtual machine, at the desk and on the release runner, on the CPU image `ghcr.io/caldrix-ai/caldrix:0.2.0-cpu` with the default model; each time `helm test` passed and one chat request answered. Not yet run on a cluster of any other kind, and not on any GPU.

## License

caldrix is free for non-commercial use. Production and commercial use need a commercial license: jyothsna@caldrix.ai. See [LICENSE.md](https://github.com/caldrix-ai/helm-charts/blob/main/LICENSE.md) and the [License Terms](https://caldrix.ai/terms).

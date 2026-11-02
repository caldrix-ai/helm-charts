# caldrix Helm charts

The Helm charts for [caldrix](https://github.com/caldrix-ai/caldrix), which runs and serves language models with
the Inferno compiler. This repository is regenerated from caldrix's private source. It holds one chart,
[`caldrix`](charts/caldrix/README.md): one `caldrix serve` of one model on Kubernetes, from the caldrix CPU image.

## Install

With Helm 3.8 or newer:

```sh
helm install caldrix oci://ghcr.io/caldrix-ai/charts/caldrix --version 0.1.0 --namespace caldrix --create-namespace
```

The pod turns Ready once the model is downloaded, compiled and loaded. Then, from another terminal, forward the
Service and read the served model; the `id` it returns is the `model` to send:

```sh
kubectl --namespace caldrix port-forward svc/caldrix 8425:80
curl http://localhost:8425/v1/models
curl http://localhost:8425/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "<id>", "messages": [{"role": "user", "content": "What is the capital of France?"}]}'
```

## Values worth knowing

| key | default | meaning |
|---|---|---|
| `model.name` | `smollm2-instruct` | the model: an alias, a hub id `owner/name[@revision]`, or `ollama:<tag>` |
| `persistence.size` | `20Gi` | the model cache's PersistentVolumeClaim |
| `huggingface.existingSecret` | `""` | an existing Secret holding a Hugging Face token, for gated models |
| `resources` | requests `cpu: 2`, `memory: 4Gi`; no limits | a CPU limit sets the server's thread count |
| `ingress.enabled` | `false` | an Ingress to the Service; the server has no authentication, so put a gateway that authenticates in front of it |

Every value, the GPU rule, storage and exposure are in the [chart's README](charts/caldrix/README.md).

## Verified

Verified: installed with kind in a virtual machine, at the desk and on the release runner, on the CPU image `ghcr.io/caldrix-ai/caldrix:0.2.0-cpu` with the default model; each time `helm test` passed and one chat request answered. Not yet run on a cluster of any other kind, and not on any GPU.

## License

caldrix is free for non-commercial use. Production and commercial use need a commercial license: jyothsna@caldrix.ai. See [LICENSE.md](LICENSE.md) and the [License Terms](https://caldrix.ai/terms).

## Bugs and security

File bugs as [issues](https://github.com/caldrix-ai/helm-charts/issues/new/choose) and include `helm version`, `kubectl version` and the chart version. Report security issues privately: see [SECURITY.md](SECURITY.md).

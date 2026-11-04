# Changelog

Every release of the `caldrix` chart, newest first.

## [0.1.1] - unreleased (dated when pushed)

### Changed

- `volumePermissions` chowns the cache volume to `podSecurityContext.runAsUser`:`fsGroup` (else `runAsGroup`, else
  10001), so an overridden pod user owns its volume; the defaults render as before (`10001:10001`).
- A probe's `httpGet` under `probes.*` is merged over the chart's `GET /healthz` (its keys win), where before it was
  appended as a second `httpGet` key.

### Fixed

- `ingress.enabled` with no `ingress.hosts` fails the install by name instead of rendering an Ingress with no rules;
  the schema refuses a host with no paths, and a `tls` entry without `secretName` or `hosts`.
- `persistence.existingClaim` with `persistence.enabled: false` fails the install by name; before, the claim was
  silently not mounted.
- The schema refuses a `model.context` that is not a positive integer.

## [0.1.0] - 2026-10-30

The first release.

### Added

- One Deployment of `caldrix serve` from the caldrix CPU image (`ghcr.io/caldrix-ai/caldrix`), one replica,
  serving `smollm2-instruct` by default, as the image's non-root user.
- A PersistentVolumeClaim for the model cache, so a restart does not download the model again.
- A ClusterIP Service on port 80 to the server's port 8425.
- An Ingress, off by default (`ingress.enabled`).
- A NetworkPolicy admitting traffic to port 8425 only, off by default (`networkPolicy.enabled`).
- The GPU rule: `gpu.enabled: true` or `model.backend: hip` renders only with `image.gpu: true`; otherwise the
  install fails with one sentence saying the ROCm image is not published yet.

Verified: installed once with kind in a virtual machine, on the CPU image `ghcr.io/caldrix-ai/caldrix:0.2.0-cpu` with the default model; `helm test` passed and one chat request answered; not on any GPU.

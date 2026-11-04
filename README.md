[![Kustomize 5.7.0](https://img.shields.io/badge/Kustomize-5.7.0-326ce5?logo=kubernetes&logoColor=white)](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.7.0)
[![Kustomize 5.8.1](https://img.shields.io/badge/Kustomize-5.8.1-326ce5?logo=kubernetes&logoColor=white)](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.8.1)
[![Scope](https://img.shields.io/badge/scope-library-0e6027)](docs/architecture.md)
[![Last commit](https://img.shields.io/github/last-commit/nick-draper/kustomize-library)](https://github.com/nick-draper/kustomize-library/commits/main)

# Kustomize library

Components for required node affinity, Argo CD labels, and sync-wave annotations. This repository is the library only. The example workloads, Minikube steps, and `kubectl` checks are in [kustomize-application](https://github.com/nick-draper/kustomize-application).

The renderers are **Kustomize 5.7.0** and **Kustomize 5.8.1**. CPU and GPU replacement strings are `sourceValue` literals. The node-affinity component patch targets Deployment, StatefulSet, and Job together with `kind: Deployment|StatefulSet|Job`. The replacement transformer lists those three kinds separately, because 5.7.0 matches a replacement kind exactly and leaves `ENV_PLACEHOLDER` and `COMPUTE_PLACEHOLDER` when the kind contains a pipe. CronJob stays separate because its PodSpec path is `spec.jobTemplate.spec.template.spec`.

## Who this is for

Platform engineers who want one affinity and sync-wave policy, with the environment chosen by the overlay and the compute profile chosen by a label on the workload.

## Components

| Path | Effect |
|------|--------|
| `components/node-affinity` | Required `my.cluster/environment` and `my.cluster/compute` terms, plus an opt-in AFM exclusion |
| `components/labels/argocd` | `app.kubernetes.io/managed-by: argocd` on the resource and the Pod template. Selectors stay unchanged |
| `components/labels/environment/{dev,qa,prod}` | `my.cluster/environment` the same way |
| `components/sync-waves` | `argocd.argoproj.io/sync-wave` on resource metadata |
| `transformers/node-affinity` | Directory the overlay lists under `transformers`. Fills `ENV_PLACEHOLDER` from the overlay and `COMPUTE_PLACEHOLDER` from `sourceValue` |
| `kustomization.yaml` | Base bundle of node affinity, the Argo CD label, and sync waves. Not a complete render |
| `docs/architecture.md` | Build order, field paths, and the overlay contract |

Set the profile on the workload, not on the Pod template:

```yaml
metadata:
  labels:
    scheduling.my.cluster/compute: gpu
```

`cpu` and `gpu` are the only profiles. The `scheduling-settings` ConfigMap supplies `data.environment` and nothing else. It is marked `config.kubernetes.io/local-config: "true"`, so it is not rendered. The tree has no credentials, tokens, or cluster endpoints.

## Pin it

Render with Kustomize 5.7.0 or 5.8.1. `kustomize version` must print `v5.7.0` or `v5.8.1`. Argo CD v3.5.6 ships 5.8.1.

The version is one full 40-character commit SHA, shared by every URL in the application. Kustomize 5.7.0 and 5.8.1 fetch it with `git fetch --depth=1`. That accepts the full SHA. It rejects a short SHA. `main`, any other branch, and a URL with no `ref` all follow the default branch, so none of them is a pin. This repository does not publish a release tag.

The base selects the shared policy. The final overlay selects the environment, patches `scheduling-settings`, and runs the transformer. Point `transformers` at the `transformers/node-affinity` directory. A URL that ends in `transformer.yaml` fails because the entry has to be a directory.

Base:

```yaml
components:
  - https://github.com/nick-draper/kustomize-library.git//components/node-affinity?ref=<40-character-sha>
  - https://github.com/nick-draper/kustomize-library.git//components/labels/argocd?ref=<40-character-sha>
  - https://github.com/nick-draper/kustomize-library.git//components/sync-waves?ref=<40-character-sha>
```

Overlay, using one of `dev`, `qa`, or `prod`:

```yaml
components:
  - https://github.com/nick-draper/kustomize-library.git//components/labels/environment/qa?ref=<40-character-sha>
patches:
  - path: environment.yaml
transformers:
  - https://github.com/nick-draper/kustomize-library.git//transformers/node-affinity?ref=<40-character-sha>
```

`environment.yaml` sets `data.environment` on `scheduling-settings`. Without that patch the affinity value stays `ENVIRONMENT_UNSET`. The repository root is only the base bundle. Referencing it leaves `ENV_PLACEHOLDER` and `COMPUTE_PLACEHOLDER` in the output, because the root does not choose an environment and does not run the transformer.

The build-order contract is in [docs/architecture.md](docs/architecture.md). Deploy and test the example with [kustomize-application](https://github.com/nick-draper/kustomize-application).

## Sync waves

These values are the imported table, not a universal dependency order. Put an exception in the application's overlay.

| Kind | Wave |
| --- | --- |
| Namespace | -10 |
| Project | -5 |
| AppProject | 1 |
| Application | 4 |
| ApplicationSet | 5 |
| CatalogSource | 6 |
| OperatorGroup | 7 |
| Subscription | 8 |
| ClusterServiceVersion | 9 |
| CustomResourceDefinition | 15 |
| StorageClass | 20 |
| PersistentVolumeClaim | 22 |
| NetworkPolicy | 25 |
| MutatingWebhookConfiguration | 26 |
| ResourceQuota | 28 |
| LimitRange | 30 |
| User | 31 |
| Group | 32 |
| Role | 33 |
| RoleBinding | 34 |
| ClusterRole | 35 |
| ClusterRoleBinding | 36 |
| ServiceAccount | 37 |
| ConfigMap | 42 |
| Secret | 44 |
| Service | 50 |
| Route | 52 |
| EventListener | 56 |
| TriggerBinding | 57 |
| TriggerTemplate | 58 |
| Task | 59 |
| Pipeline | 60 |
| Operand | 62 |
| Deployment | 70 |
| StatefulSet | 70 |
| DaemonSet | 74 |
| Job | 76 |
| CronJob | 78 |
| HorizontalPodAutoscaler | 80 |
| PodDisruptionBudget | 82 |
| Prometheus | 84 |
| ServiceMonitor | 86 |
| Alertmanager | 88 |
| Backup | 90 |
| Schedule | 92 |

## Out of scope

- Example workloads and overlays. Those are [kustomize-application](https://github.com/nick-draper/kustomize-application)
- Applying this library by itself. It has no workload until an application selects it
- GPU device requests. Affinity only requires the node label `my.cluster/compute`
- Kustomize versions other than 5.7.0 and 5.8.1

## License

Released under the [MIT License](LICENSE).

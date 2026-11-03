[![Kustomize](https://img.shields.io/badge/Kustomize-5.8.1-326ce5?logo=kubernetes&logoColor=white)](https://github.com/kubernetes-sigs/kustomize/releases/tag/kustomize%2Fv5.8.1)
[![Scope](https://img.shields.io/badge/scope-library-0e6027)](docs/architecture.md)
[![Last commit](https://img.shields.io/github/last-commit/nick-draper/kustomize-library)](https://github.com/nick-draper/kustomize-library/commits/main)

# Kustomize library

Components for required node affinity, Argo CD labels, and sync-wave annotations. This repository is the library only. The example workloads, Minikube steps, and `kubectl` checks are in [kustomize-application](https://github.com/nick-draper/kustomize-application).

The renderer is **Kustomize 5.8.1**. CPU and GPU replacement strings are `sourceValue` literals. Deployment, StatefulSet, and Job share `kind: Deployment|StatefulSet|Job`. CronJob stays separate because its PodSpec path is `spec.jobTemplate.spec.template.spec`.

## Who this is for

Platform engineers who want one affinity and sync-wave policy, with the environment chosen by the overlay and the compute profile chosen by a label on the workload.

## Components

| Path | Effect |
|------|--------|
| `components/node-affinity` | Required `my.cluster/environment` and `my.cluster/compute` terms, plus an opt-in AFM exclusion |
| `components/labels/argocd` | `app.kubernetes.io/managed-by: argocd` on the resource and the Pod template. Selectors stay unchanged |
| `components/labels/environment/{dev,qa,prod}` | `my.cluster/environment` the same way |
| `components/sync-waves` | `argocd.argoproj.io/sync-wave` on resource metadata |
| `transformers/node-affinity` | Fills `ENV_PLACEHOLDER` from the overlay and `COMPUTE_PLACEHOLDER` from `sourceValue` |

Set the profile on the workload, not on the Pod template:

```yaml
metadata:
  labels:
    scheduling.my.cluster/compute: gpu
```

`cpu` and `gpu` are the only profiles. The `scheduling-settings` ConfigMap supplies `data.environment` and nothing else. It is marked `config.kubernetes.io/local-config: "true"`, so it is not rendered.

## Pin it

Use the same commit for every reference:

```yaml
components:
  - https://github.com/nick-draper/kustomize-library.git//components/node-affinity?ref=<commit>
  - https://github.com/nick-draper/kustomize-library.git//components/labels/argocd?ref=<commit>
  - https://github.com/nick-draper/kustomize-library.git//components/sync-waves?ref=<commit>
transformers:
  - https://github.com/nick-draper/kustomize-library.git//transformers/node-affinity?ref=<commit>
```

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
- Kustomize versions other than 5.8.1

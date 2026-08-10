+++
title = 'Validate Kubernetes Manifests (Including CRDs) with Kubeconform'
date = 2026-08-10T00:00:00+02:00
categories = ['devops']
tags = ['kubernetes', 'kubeconform', 'validation', 'crd', 'ci']
+++

Applying a manifest just to discover a typo in a field name is a slow feedback loop. [Kubeconform](https://github.com/yannh/kubeconform) gives you that feedback in milliseconds: it validates Kubernetes YAML against the official API schemas, offline and pinned to the exact cluster version you run.

## Why not just `kubectl apply --dry-run`?

A dry run needs a live cluster and validates against whatever version that cluster happens to be. Kubeconform works anywhere: on your laptop, in a pre-commit hook, or in a CI job, and it lets you target a specific Kubernetes version. It is also fast enough to run on every commit.

## The CRD gap

Out of the box, schema validation only covers built-in resources. Anything defined by a CRD is unknown to the default schemas, whether it is a Gateway API `HTTPRoute`, a cert-manager `Certificate`, or an Argo `Application`. The [Datree CRDs catalog](https://github.com/datreeio/CRDs-catalog) fills that gap: it hosts JSON schemas for hundreds of popular CRDs, and Kubeconform can pull them on the fly via a templated schema location.

## The command

```bash
kubeconform -summary \
  -kubernetes-version 1.33.5 \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  httproute.yaml
```

What each part does:

- `-summary` prints a one-line count of valid, invalid, and skipped resources at the end.
- `-kubernetes-version 1.33.5` validates against the schemas of that exact release instead of "latest", so the check matches your real cluster.
- The first `-schema-location default` keeps the standard schemas for built-in kinds like Deployments and Services.
- The second `-schema-location` is a URL template: Kubeconform substitutes `{{.Group}}`, `{{.ResourceKind}}`, and `{{.ResourceAPIVersion}}` per resource and fetches the matching schema from the CRDs catalog. For an `HTTPRoute` that resolves to `gateway.networking.k8s.io/httproute_v1.json`.

The output looks like this:

```text
Summary: 1 resource found in 1 file - Valid: 1, Invalid: 0, Errors: 0, Skipped: 0
```

Drop the same command into CI (or pipe `helm template` / `kustomize build` into it) and broken manifests never reach the cluster.

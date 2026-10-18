# Plotwork examples

A small, made-up company, Parcelpoint, whose diagrams are made from its own files and kept in step with them by [Plotwork](https://plotwork.dev): Terraform, Bicep, an ARM template, Pulumi, CloudFormation, a CDK cloud assembly, an OpenAPI document, AsyncAPI documents, a Docker Compose file, Kubernetes manifests, a Helm chart, Kustomize overlays, a Backstage catalog, a Structurizr workspace, a SQL schema, GitHub Actions, GitLab CI/CD and Azure Pipelines files, and a CSV. Copy what you need. The same repository is the smoke test of every Plotwork release: its workflows run the GitHub Action and the command line against it after each release.

## TL;DR

| Question | Answer |
|---|---|
| Where are the diagrams? | All on one page: [the gallery](docs/README.md). In `docs/`: one `.diagram` file and one SVG for each source, and one in a fence of [docs/architecture.md](docs/architecture.md). Hand-written examples of other kinds are in [diagrams/](diagrams/README.md). |
| Why do the pictures look right in GitHub's dark mode? | `"schemes": "auto"` in the `defaults` of [plotwork.config.json](plotwork.config.json): each SVG holds a light and a dark version and shows the one the reader's theme uses, as a file, a link, or a plain `<img>`. |
| What says which file makes which diagram? | The `sources` of [plotwork.config.json](plotwork.config.json). |
| How do I change a generated diagram? | In its overrides file, such as [docs/infra.overrides.json](docs/infra.overrides.json), which relabels three resources. Never in the generated file. |
| What fails a pull request? | [check.yml](.github/workflows/check.yml): a generated diagram that no longer matches its files, or a hand-written diagram with an error. |
| What writes them back? | [regenerate.yml](.github/workflows/regenerate.yml), nightly and on each push to `main`, opens or edits one pull request, and closes it once nothing drifts. |
| Can my team call it from our repositories? | Three reusable workflows (`workflow_call`), one for each set of permissions: [plotwork-check.yml](.github/workflows/plotwork-check.yml) (`contents: read`), [plotwork-scan.yml](.github/workflows/plotwork-scan.yml) (adds `security-events: write` for code scanning) and [plotwork-regenerate.yml](.github/workflows/plotwork-regenerate.yml) (`contents: write`, `pull-requests: write`). This repository's `check.yml` calls the first. |
| How fast is it on a big monorepo? | [scale.yml](.github/workflows/scale.yml) makes one in the job (24 sources by default, hundreds of resources and endpoints), and measures a write and a check on the runner. |
| What proves a release works? | [smoke.yml](.github/workflows/smoke.yml), after each release of the Action or the command line, nightly, and by hand. |
| Can I run it on my machine? | `npx @buun_group/plotwork generate --check` in a clone. Nothing leaves the machine. |

## Layout

| Path | What it is | Diagram |
|---|---|---|
| `infra/terraform/` | The Azure stack in Terraform: four modules and the `dev` and `prod` environments that call them. See [infra/README.md](infra/README.md). | `docs/infra.diagram` (prod) and `docs/infra-dev.diagram` |
| `infra/bicep/`, `infra/pulumi/` | The same stack in Bicep, and as a Pulumi program and a stack export. | `docs/infra-bicep.diagram`, `docs/infra-pulumi.diagram`, `docs/infra-pulumi-state.diagram` |
| `infra/arm/` | The label and event services as an ARM template. | `docs/infra-arm.diagram` |
| `infra/cloudformation/` | The tracking API on AWS as a SAM template. | `docs/infra-aws.diagram` |
| `infra/cdk/cdk.out/` | The label printing service on AWS, as `cdk synth` writes it: two stacks, constructs, and a nested stack of alerts. | `docs/infra-cdk.diagram` |
| `compose.yaml` | The stack a developer runs. | The `services` fence of `docs/architecture.md` |
| `k8s/*.yaml` | The same services on Kubernetes. | `docs/cluster.diagram` |
| `deploy/helm/tracking/` | The tracking chart: its dependencies, the versions `Chart.lock` resolved, and a cache its values switch off. | `docs/helm-chart.diagram` |
| `deploy/helm/rendered/tracking.yaml` | What `helm template` renders from that chart, framed by release and chart. | `docs/helm-release.diagram` |
| `deploy/kustomize/webhook-sender/` | The webhook sender's base, `dev` and `prod` overlays, and a tracing component. | `docs/kustomize.diagram` |
| `deploy/kustomize/built/webhook-sender-prod.yaml` | What `kustomize build overlays/prod` writes. | `docs/kustomize-prod.diagram` |
| `api/openapi.json` | The tracking API. | `docs/api.diagram` (by tag) and `docs/api-access.diagram` (who may call each endpoint) |
| `events/*.asyncapi.yaml` | The messages on RabbitMQ: the API and the worker in AsyncAPI 3, the webhook sender in AsyncAPI 2, meeting on shared channels. | `docs/events.diagram` |
| `catalog/` | The Backstage catalog: a domain, three systems, their components, APIs, and resources, and the teams and people who own them. | `docs/catalog.diagram` (by system) and `docs/catalog-teams.diagram` (by owner) |
| `architecture/workspace.dsl` | The C4 model in the Structurizr DSL: people, containers, components, and the systems around them. | `docs/c4-containers.diagram` |
| `db/schema.sql` | The tracking database. | `docs/database.diagram` |
| `.github/workflows/check.yml` | This repository's pull request check. | `docs/ci.diagram` |
| `pipelines/gitlab/.gitlab-ci.yml` | The webhook sender's pipeline on GitLab, where its mirror runs: `needs`, `rules`, a manual deploy, and two triggers. | `docs/ci-gitlab.diagram` |
| `pipelines/azure/azure-pipelines.yml` | The label service's pipeline on Azure Pipelines: stages, `dependsOn`, and deployment jobs to environments. | `docs/ci-azure.diagram` |
| `data/shipments.csv` | Monthly shipments by region. | `docs/shipments.diagram` |
| `docs/README.md` | The gallery: every generated diagram, with what it is made from. | |
| `diagrams/` | Hand-written diagrams of other kinds. | |

## The smoke test

| Step | What it proves |
|---|---|
| a | On a clean tree, `generate` in check mode passes, and the command line finds no change. |
| b | A Terraform resource added to `infra/terraform/envs/prod/main.tf` in the job fails the check, the `changes` output names the new node, and the command line agrees. |
| c | Write mode with `on-drift: pr` opens a pull request from a branch of the run, holding the new resource and its diagram, and that pull request's `check` run passes. When the token that opened it starts no workflow, the check is skipped with a notice. |
| d | A second run finds nothing to do, closes that pull request, and deletes its branch. |
| e | An override's label survives regeneration, and an override whose resource is gone warns without failing. |
| g | With the secret `PLOTWORK_API_KEY` and the variable `PLOTWORK_API_URL` (the API the key belongs to), publishing serves an SVG: a personal key's stable link to anyone, an organisation key's library picture to the key. A second job reads the whole log and checks the key is in it nowhere. Without the secret, the step is skipped. |

The pull request and its branch are removed at the end of every run, whatever happened; a run of the branch that is still going is cancelled first, so none is left to fail once the branch is gone. The repository must allow GitHub Actions to create pull requests (Settings, Actions, General).

## Where it comes from

This repository is a mirror. Its source is the `examples/` folder of the Plotwork monorepo, and every change arrives as one commit from there; a pull request here is read, but merged there.

## Licence

[MIT](LICENSE). Parcelpoint and everything about it is invented.

## See also

| Page | Why |
|---|---|
| [Diagrams as code](https://docs.plotwork.dev/diagrams-as-code) | The guide to `sources`, overrides, drift, and the workflows |
| [plotwork-action](https://github.com/plotwork-official/plotwork-action) | The GitHub Action |
| [@buun_group/plotwork](https://www.npmjs.com/package/@buun_group/plotwork) | The command line |

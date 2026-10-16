# Plotwork examples

A small, made-up company, Parcelpoint, whose diagrams are made from its own files and kept in step with them by [Plotwork](https://plotwork.dev): Terraform, an OpenAPI document, a Docker Compose file, Kubernetes manifests, a SQL schema, a GitHub Actions workflow, and a CSV. Copy what you need. The same repository is the smoke test of every Plotwork release: its workflows run the GitHub Action and the command line against it after each release.

## TL;DR

| Question | Answer |
|---|---|
| Where are the diagrams? | In `docs/`: one `.diagram` file with a light and a dark SVG for each source, and one in a fence of [docs/architecture.md](docs/architecture.md). Hand-written examples of other kinds are in [diagrams/](diagrams/README.md). |
| What says which file makes which diagram? | The `sources` of [plotwork.config.json](plotwork.config.json). |
| How do I change a generated diagram? | In its overrides file, such as [docs/infra.overrides.json](docs/infra.overrides.json), which relabels three resources and hides the internet gateway. Never in the generated file. |
| What fails a pull request? | [check.yml](.github/workflows/check.yml): a generated diagram that no longer matches its files, or a hand-written diagram with an error. |
| What writes them back? | [regenerate.yml](.github/workflows/regenerate.yml), nightly and on each push to `main`, opens or edits one pull request, and closes it once nothing drifts. |
| What proves a release works? | [smoke.yml](.github/workflows/smoke.yml), after each release of the Action or the command line, nightly, and by hand. |
| Can I run it on my machine? | `npx @buun_group/plotwork generate --check` in a clone. Nothing leaves the machine. |

## Layout

| Path | What it is | Diagram |
|---|---|---|
| `infra/*.tf` | The AWS stack: a VPC, a load balancer, two ECS services, Postgres, S3, and SQS. | `docs/infra.diagram` |
| `compose.yaml` | The stack a developer runs. | The `services` fence of `docs/architecture.md` |
| `k8s/*.yaml` | The same services on Kubernetes. | `docs/cluster.diagram` |
| `api/openapi.json` | The tracking API. | `docs/api.diagram` (by tag) and `docs/api-access.diagram` (who may call each endpoint) |
| `db/schema.sql` | The tracking database. | `docs/database.diagram` |
| `.github/workflows/check.yml` | This repository's pull request check. | `docs/ci.diagram` |
| `data/shipments.csv` | Monthly shipments by region. | `docs/shipments.diagram` |
| `diagrams/` | Hand-written diagrams of other kinds. | |

## The smoke test

| Step | What it proves |
|---|---|
| a | On a clean tree, `generate` in check mode passes, and the command line finds no change. |
| b | A Terraform resource added in the job fails the check, the `changes` output names the new node, and the command line agrees. |
| c | Write mode with `on-drift: pr` opens a pull request from a branch of the run, holding the new diagram. |
| d | A second run finds nothing to do, closes that pull request, and deletes its branch. |
| e | An override's label survives regeneration, and an override whose resource is gone warns without failing. |
| g | With the secret `PLOTWORK_API_KEY`, publishing to a stable link serves an SVG, and the key is in no log. Without it, the step is skipped. |

The pull request and its branch are removed at the end of every run, whatever happened. The repository must allow GitHub Actions to create pull requests (Settings, Actions, General).

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

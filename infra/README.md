# Parcelpoint infrastructure

Parcelpoint's tracking platform on Azure, written three ways: Terraform, Bicep, and Pulumi. Beside them, its label and event services as an ARM template, its tracking API on AWS as a CloudFormation (SAM) template, and its label printing service on AWS as a CDK cloud assembly. Each describes the same network, data services, and apps, with the same names, so the diagrams [Plotwork](https://plotwork.dev) makes from them are the same picture. Pick the folder of the tool you use and copy what you need.

## TL;DR

| Question | Answer |
|---|---|
| What runs? | The tracking API and the carrier event worker on one App Service plan, joined to the app subnet; Postgres in a delegated subnet with a private DNS zone; label PDFs in blob storage behind a private endpoint; carrier events on a Service Bus queue; the database password in Key Vault; one managed identity the data services grant access to; and one Log Analytics workspace that the apps' telemetry and the security group's flow events go to. |
| How is it named? | `<kind>-<org>-<environment>[-<role>]`, such as `app-parcel-prod-api`, made with `format()` from the organisation and the environment. Storage accounts drop the hyphens: `stparcelprodlabels`. |
| How is it tagged? | Every resource carries `environment`, `application`, and `managed_by`, merged with tags each environment adds, such as `cost_centre`. |
| Which environments? | `dev` and `prod`, which differ only in sizes, address ranges, and replication. |
| How is it drawn? | `plotwork generate` imports each tool's files with `import_source`. Terraform modules and Bicep modules are frames around their resources (monitoring, network, data, compute); Pulumi's stack export draws its components as frames. |
| Is any of it real? | No. Every name, address, and id is invented, and no account or subscription id is a real one. |

## Layout

| Path | What it is |
|---|---|
| `terraform/modules/monitoring` | The Log Analytics workspace and Application Insights. |
| `terraform/modules/network` | The virtual network, a subnet for each tier made with `for_each`, the app subnet's security group and its diagnostic setting, and the database's private DNS zone. |
| `terraform/modules/data` | Postgres and its database, label storage and its private endpoint, the Service Bus queue, and Key Vault with the database password. |
| `terraform/modules/compute` | The managed identity and its role assignments (`for_each` over a local), the plan, the API, and the worker. |
| `terraform/envs/dev`, `terraform/envs/prod` | One root module per environment: the resource group and the four modules, with names from `locals`, tags from `merge()`, and values in `terraform.tfvars`. Variables have descriptions, types, and validation. |
| `bicep/main.bicep` | The subscription-scoped deployment: the resource group and the four modules of `bicep/modules`, with parameters described and allowed values listed. |
| `bicep/main.dev.bicepparam`, `bicep/main.prod.bicepparam` | Each environment's values. |
| `pulumi/Pulumi.yaml` | The same stack as a Pulumi YAML program, with names made by `${}` interpolation and `fn::join`. |
| `pulumi/Pulumi.dev.yaml`, `pulumi/Pulumi.prod.yaml` | Each stack's configuration. |
| `arm/azuredeploy.json`, `arm/azuredeploy.parameters.json` | The label storage, the carrier events queue, and the worker that reads them, with its role assignments, as `az bicep build` writes a template. |
| `cloudformation/template.yaml` | The tracking API on AWS: an API Gateway route to a Lambda, parcels in DynamoDB, labels in S3, and carrier events on SQS with a dead-letter queue. |
| `cdk/cdk.out/` | The label printing service on AWS as `cdk synth` writes it: the `LabelStorage` stack exports the label bucket, and the `LabelPrinting` stack holds the intake function and its URL, the request queue with its dead-letter queue, the jobs table, the renderer, and the `Alerts` nested stack with an alarm on the dead letters. |
| `pulumi/stack-export.json` | What `pulumi stack export` writes for the production stack of a program that groups the resources in four components, `Monitoring`, `Network`, `Data`, and `Compute`, as a TypeScript program would. |

## Drawing one

| Tool | Command |
|---|---|
| Terraform | `npx @buun_group/plotwork import-source terraform infra/terraform --root envs/prod` |
| Bicep | `npx @buun_group/plotwork import-source bicep infra/bicep --var-file main.prod.bicepparam` |
| Pulumi | `npx @buun_group/plotwork import-source pulumi infra/pulumi --root Pulumi.yaml --var-file Pulumi.prod.yaml` |
| Pulumi, from its state | `npx @buun_group/plotwork import-source pulumi infra/pulumi/stack-export.json` |
| ARM | `npx @buun_group/plotwork import-source arm infra/arm` |
| CloudFormation | `npx @buun_group/plotwork import-source cloudformation infra/cloudformation/template.yaml` |
| CDK | `npx @buun_group/plotwork import-source cdk infra/cdk/cdk.out` |

## See also

| Page | Why |
|---|---|
| [Importing from code and data](https://docs.plotwork.dev/importing-from-code-and-data) | What each tool's files draw, and the options |
| [Diagrams as code](https://docs.plotwork.dev/diagrams-as-code) | Keeping a diagram in step with these files in CI |
| [The examples README](../README.md) | The rest of Parcelpoint |

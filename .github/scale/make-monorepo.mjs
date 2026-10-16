#!/usr/bin/env node
/**
 * Writes a synthetic monorepo for the scale test: `teams` teams, each with a Terraform stack of modules, an OpenAPI document, and a
 * Compose file, and one plotwork.config.json with a source for each. Nothing here is real; the names are numbered.
 *
 *   node make-monorepo.mjs <folder> [teams=8] [resources per team=70] [endpoints per team=120]
 *
 * Eight teams of 70 resources make 560 Terraform resources across 32 modules, 960 endpoints, and 24 sources.
 */
import { mkdirSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'

const [folder, teamsArg = '8', resourcesArg = '70', endpointsArg = '120'] = process.argv.slice(2)
if (folder === undefined) {
  console.error('usage: make-monorepo.mjs <folder> [teams] [resources per team] [endpoints per team]')
  process.exit(2)
}
const teams = Number(teamsArg)
const resources = Number(resourcesArg)
const endpoints = Number(endpointsArg)

const write = (path, text) => {
  mkdirSync(join(folder, path, '..'), { recursive: true })
  writeFileSync(join(folder, path), text)
}

/** One module of a team's stack: queues, buckets, and functions that read them, so the import has arrows to draw. */
function module(team, index, count) {
  const lines = []
  for (let at = 0; at < count; at += 1) {
    const id = `t${team}_m${index}_${at}`
    if (at % 3 === 0) lines.push(`resource "aws_sqs_queue" "${id}" {\n  name = "${id.replaceAll('_', '-')}"\n}\n`)
    else if (at % 3 === 1) lines.push(`resource "aws_s3_bucket" "${id}" {\n  bucket = "${id.replaceAll('_', '-')}"\n}\n`)
    else lines.push(`resource "aws_lambda_function" "${id}" {\n  function_name = "${id.replaceAll('_', '-')}"\n  role          = "arn:aws:iam::123456789012:role/${id}"\n  environment {\n    variables = {\n      QUEUE  = aws_sqs_queue.t${team}_m${index}_${at - 2}.url\n      BUCKET = aws_s3_bucket.t${team}_m${index}_${at - 1}.bucket\n    }\n  }\n}\n`)
  }
  return lines.join('\n')
}

/** An OpenAPI document of `count` operations across ten tags. */
function openapi(team, count) {
  const paths = {}
  for (let at = 0; at < count; at += 1) {
    const tag = `area${at % 10}`
    paths[`/team${team}/${tag}/items${at}`] = { get: { operationId: `get${team}x${at}`, tags: [tag], summary: `Item ${at}`, responses: { 200: { description: 'ok' } } } }
  }
  return `${JSON.stringify({ openapi: '3.0.3', info: { title: `Team ${team} API`, version: '1.0.0' }, paths }, null, 2)}\n`
}

const sources = []
for (let team = 1; team <= teams; team += 1) {
  const perModule = Math.ceil(resources / 4)
  for (let index = 0; index < 4; index += 1) write(`teams/${team}/infra/module${index}/main.tf`, module(team, index, Math.min(perModule, resources - perModule * index)))
  write(`teams/${team}/api/openapi.json`, openapi(team, endpoints))
  write(`teams/${team}/compose.yaml`, `services:\n  web:\n    image: nginx:1.27\n    depends_on: [api]\n  api:\n    image: ghcr.io/team${team}/api:1.0.0\n    depends_on: [db]\n  db:\n    image: postgres:16\n`)
  sources.push(
    { name: `team${team}-infra`, from: `teams/${team}/infra/**/*.tf`, format: 'terraform', out: `teams/${team}/docs/infra.diagram`, pictures: true },
    { name: `team${team}-api`, from: `teams/${team}/api/openapi.json`, format: 'openapi', view: 'map', out: `teams/${team}/docs/api.diagram` },
    { name: `team${team}-services`, from: `teams/${team}/compose.yaml`, format: 'compose', out: `teams/${team}/docs/services.diagram` },
  )
}
write('plotwork.config.json', `${JSON.stringify({ sources }, null, 2)}\n`)
process.stdout.write(`${teams} teams, ${teams * resources} Terraform resources in ${teams * 4} modules, ${teams * endpoints} endpoints, ${sources.length} sources in ${folder}\n`)

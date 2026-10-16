# Hand-written diagrams

Diagrams of Parcelpoint written by hand in the Plotwork language, one file for each kind that is not made from a file of the repository. The check workflow fails a pull request in which one has an error.

## TL;DR

| Question | Answer |
|---|---|
| How do I draw one? | `npx @buun_group/plotwork render diagrams/parcel-status.diagram --out parcel-status.svg`. |
| How do I check them all? | `npx @buun_group/plotwork validate diagrams/<file>`, or the Action with `command: check` and `diagrams: diagrams/**/*.diagram`. |

## Contents

| File | Kind | What it shows |
|---|---|---|
| `tracking-event.diagram` | flow | A carrier scan on its way to the tracking page and the merchant's webhook |
| `create-shipment.diagram` | sequence | A merchant creating a shipment, with the carrier down |
| `parcel-status.diagram` | state | The life of a parcel |
| `roadmap.diagram` | gantt | The work of the fourth quarter |
| `product.diagram` | mindmap | What Parcelpoint offers |
| `context.diagram` | c4 | Who uses Parcelpoint and what it talks to |
| `customer-journey.diagram` | journey | How a customer feels while waiting |
| `history.diagram` | timeline | The company so far |

## See also

| Page | Why |
|---|---|
| [README](../README.md) | The generated diagrams and the workflows |
| [Writing diagrams](https://docs.plotwork.dev/writing-diagrams) | The language |

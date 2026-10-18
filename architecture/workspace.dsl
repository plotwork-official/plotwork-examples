/*
 * Parcelpoint: the C4 model of the tracking platform, its people, and the systems around it.
 * The same story as docs/architecture.md, catalog/, and infra/: every container here is deployed by one of them.
 */
workspace "Parcelpoint" "Creates shipments, prints labels, and tracks parcels to the door." {

    !identifiers hierarchical

    model {
        enterprise "Parcelpoint" {
            merchant = person "Merchant" "Ships goods to customers."
            support = person "Support agent" "Answers where a parcel is."

            parcelpoint = softwareSystem "Parcelpoint" "Creates shipments, prints labels, and tracks parcels." {
                dashboard = container "Merchant dashboard" "Creates shipments and prints labels." "React" {
                    tags "Web Browser"
                }
                api = container "Tracking API" "Shipments, parcels, and their events over HTTPS." "TypeScript" {
                    shipments = component "Shipments" "Creates a shipment and asks for its labels." "Hono route"
                    parcels = component "Parcels" "Answers where a parcel is and what happened to it." "Hono route"
                    carrierHook = component "Carrier webhook" "Takes a carrier's scan and queues it." "Hono route"
                    store = component "Parcel store" "Reads and writes shipments and parcels." "Drizzle"
                }
                worker = container "Carrier event worker" "Moves each parcel along as scans arrive." "TypeScript"
                webhooks = container "Webhook sender" "Posts parcel events to merchants' webhooks." "Go"
                labels = container "Label service" "Renders each carrier's label as a PDF." "AWS Lambda"
                db = container "Tracking database" "Merchants, shipments, parcels, and events." "PostgreSQL" {
                    tags "Database"
                }
                queue = container "Carrier events" "Scans waiting to be applied." "RabbitMQ" {
                    tags "Queue"
                }
                labelStore = container "Label PDFs" "Every printed label, kept for a year." "Amazon S3" {
                    tags "Database"
                }
            }
        }

        customer = person "Customer" "Waits for a parcel." {
            tags "External"
        }
        carrier = softwareSystem "Carriers" "Collect and deliver parcels, and report each scan." {
            tags "External"
        }
        email = softwareSystem "Email service" "Sends tracking updates." {
            tags "External"
        }

        merchant -> parcelpoint.dashboard "Creates shipments with" "HTTPS"
        support -> parcelpoint.dashboard "Looks parcels up on" "HTTPS"
        customer -> parcelpoint.api "Follows a parcel on" "HTTPS"

        parcelpoint.dashboard -> parcelpoint.api.shipments "Creates shipments" "JSON/HTTPS"
        parcelpoint.dashboard -> parcelpoint.api.parcels "Reads parcels" "JSON/HTTPS"
        carrier -> parcelpoint.api.carrierHook "Reports scans" "Webhooks"

        parcelpoint.api.shipments -> parcelpoint.api.store "Saves shipments with"
        parcelpoint.api.parcels -> parcelpoint.api.store "Reads parcels with"
        parcelpoint.api.shipments -> parcelpoint.labels "Asks for labels" "HTTPS, signed"
        parcelpoint.api.carrierHook -> parcelpoint.queue "Queues scans on" "AMQP"
        parcelpoint.api.store -> parcelpoint.db "Reads and writes" "SQL"

        parcelpoint.worker -> parcelpoint.queue "Takes scans from" "AMQP"
        parcelpoint.worker -> parcelpoint.db "Updates parcels in" "SQL"
        parcelpoint.worker -> parcelpoint.webhooks "Hands parcel events to" "AMQP"
        parcelpoint.worker -> email "Sends updates through" "HTTPS"
        parcelpoint.webhooks -> merchant "Posts parcel events to" "Webhooks"
        parcelpoint.labels -> carrier "Books labels with" "HTTPS"
        parcelpoint.labels -> parcelpoint.labelStore "Keeps PDFs in" "S3"
        email -> customer "Emails"
    }

    views {
        container parcelpoint "containers" {
            include *
            title "Parcelpoint's containers"
            autolayout tb
        }
        systemContext parcelpoint "context" {
            include *
            title "Parcelpoint in context"
            autolayout tb
        }
        component parcelpoint.api "api-components" {
            include *
            title "Inside the tracking API"
            autolayout lr
        }
        styles {
            element "Database" {
                shape Cylinder
            }
            element "Queue" {
                shape Pipe
            }
            element "External" {
                background #999999
            }
        }
        theme default
    }
}

-- The tracking database: merchants send shipments, each shipment is one or more parcels, and carriers report events.
CREATE TABLE merchants (
  id          BIGSERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  api_token   TEXT NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE shipments (
  id           BIGSERIAL PRIMARY KEY,
  merchant_id  BIGINT NOT NULL REFERENCES merchants(id),
  reference    TEXT NOT NULL,
  label_key    TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE parcels (
  id           BIGSERIAL PRIMARY KEY,
  shipment_id  BIGINT NOT NULL REFERENCES shipments(id),
  code         TEXT NOT NULL UNIQUE,
  weight_grams INTEGER NOT NULL,
  status       TEXT NOT NULL DEFAULT 'created'
);

CREATE TABLE parcel_events (
  id           BIGSERIAL PRIMARY KEY,
  parcel_id    BIGINT NOT NULL REFERENCES parcels(id),
  carrier      TEXT NOT NULL,
  kind         TEXT NOT NULL,
  happened_at  TIMESTAMPTZ NOT NULL
);

CREATE TABLE webhooks (
  id           BIGSERIAL PRIMARY KEY,
  merchant_id  BIGINT NOT NULL REFERENCES merchants(id),
  url          TEXT NOT NULL,
  secret       TEXT NOT NULL
);

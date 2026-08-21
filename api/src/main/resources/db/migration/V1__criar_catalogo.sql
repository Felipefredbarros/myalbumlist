CREATE TABLE artist (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mbid        uuid NOT NULL UNIQUE,
    name        varchar(300) NOT NULL,
    sort_name   varchar(300),
    image_url   text,
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE album (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mbid          uuid NOT NULL UNIQUE,
    artist_id     uuid NOT NULL REFERENCES artist (id),
    title         varchar(500) NOT NULL,
    release_year  smallint,
    cover_url     text,
    track_count   smallint,
    created_at    timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT album_ano_plausivel
        CHECK (release_year IS NULL OR release_year BETWEEN 1860 AND 2100)
);

CREATE INDEX idx_album_artist ON album (artist_id);

CREATE TABLE track (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    album_id      uuid NOT NULL REFERENCES album (id) ON DELETE CASCADE,
    track_number  smallint NOT NULL,
    title         varchar(500) NOT NULL,
    duration_ms   integer,
    CONSTRAINT track_numero_positivo
        CHECK (track_number > 0),
    CONSTRAINT track_duracao_positiva
        CHECK (duration_ms IS NULL OR duration_ms > 0),
    CONSTRAINT track_numero_unico
        UNIQUE (album_id, track_number)
);

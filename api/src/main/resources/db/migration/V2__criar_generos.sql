CREATE TABLE genre (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mbid        uuid UNIQUE,
    name        varchar(120) NOT NULL,
    slug        varchar(120) NOT NULL UNIQUE,
    created_at  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT genre_slug_formato
        CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$')
);

CREATE TABLE genre_parent (
    genre_id   uuid NOT NULL REFERENCES genre (id) ON DELETE CASCADE,
    parent_id  uuid NOT NULL REFERENCES genre (id) ON DELETE CASCADE,
    PRIMARY KEY (genre_id, parent_id),
    CONSTRAINT genre_parent_sem_autorreferencia
        CHECK (genre_id <> parent_id)
);

CREATE INDEX idx_genre_parent_pai ON genre_parent (parent_id);

CREATE TABLE genre_alias (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    genre_id         uuid NOT NULL REFERENCES genre (id) ON DELETE CASCADE,
    external_name    varchar(200) NOT NULL,
    external_source  varchar(40) NOT NULL,
    CONSTRAINT genre_alias_unico
        UNIQUE (external_source, external_name)
);

CREATE INDEX idx_genre_alias_genero ON genre_alias (genre_id);

CREATE TABLE album_genre (
    album_id    uuid NOT NULL REFERENCES album (id) ON DELETE CASCADE,
    genre_id    uuid NOT NULL REFERENCES genre (id) ON DELETE CASCADE,
    is_primary  boolean NOT NULL DEFAULT false,
    vote_count  integer NOT NULL DEFAULT 0,
    PRIMARY KEY (album_id, genre_id),
    CONSTRAINT album_genre_votos_nao_negativos
        CHECK (vote_count >= 0)
);

CREATE INDEX idx_album_genre_genero ON album_genre (genre_id);

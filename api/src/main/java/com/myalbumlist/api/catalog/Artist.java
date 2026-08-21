package com.myalbumlist.api.catalog;

import jakarta.persistence.*;
import java.time.Instant;
import java.util.Objects;
import java.util.UUID;

@Entity
@Table(name = "artist")
class Artist {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id")
    private UUID id;

    @Column(name = "mbid", nullable = false, unique = true)
    private UUID mbid;

    @Column(name = "name", nullable = false, length = 300)
    private String name;

    @Column(name = "sort_name", length = 300)
    private String sortName;

    @Column(name = "image_url", columnDefinition = "text")
    private String imageUrl;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    protected Artist() {
    }

    Artist(UUID mbid, String name) {
        this.mbid = mbid;
        this.name = name;
    }

    UUID getId() { return id; }
    UUID getMbid() { return mbid; }
    String getName() { return name; }
    void setName(String name) { this.name = name; }
    String getSortName() { return sortName; }
    void setSortName(String sortName) { this.sortName = sortName; }
    String getImageUrl() { return imageUrl; }
    void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
    Instant getCreatedAt() { return createdAt; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Artist other)) return false;
        return id != null && id.equals(other.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}

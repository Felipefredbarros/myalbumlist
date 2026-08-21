package com.myalbumlist.api.catalog;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
import java.util.UUID;

interface ArtistRepository extends JpaRepository<Artist, UUID> {

    Optional<Artist> findByMbid(UUID mbid);
}

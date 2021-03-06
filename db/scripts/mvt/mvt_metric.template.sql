-- !METRIC!: 1 date
CREATE OR REPLACE FUNCTION mvt_!REGION!_!METRIC!(
    z integer,
    x integer, 
    y integer,
	b integer,
	gids integer[],
	d date
) RETURNS BYTEA AS $$
DECLARE
	te GEOMETRY := ST_TileEnvelope(z, x, y);
BEGIN
    RETURN (
		WITH mvtgeom AS (
			WITH t AS (
				SELECT j.fk, NTILE(b) OVER (ORDER BY j.!METRIC!) quint
				FROM jhu.!REGION! j
				WHERE j.fk = ANY(gids) AND j.date = d
			)
			SELECT t.quint, ST_AsMVTGeom(r.geom, te) geom
			FROM regions.!REGION! r
			LEFT JOIN t ON r.gid = t.fk
			WHERE r.gid = ANY(gids) AND ST_Intersects(r.geom, te)
    	) SELECT ST_AsMVT(mvtgeom.*) FROM mvtgeom
	);
END;
$$ LANGUAGE plpgsql;

-- !METRIC!: 2 date
CREATE OR REPLACE FUNCTION mvt_!REGION!_!METRIC!(
    z integer,
    x integer, 
    y integer,
	b integer,
	gids integer[],
	d1 date,
	d2 date
) RETURNS BYTEA AS $$
DECLARE
	te GEOMETRY := ST_TileEnvelope(z, x, y);
BEGIN
    RETURN (
		WITH mvtgeom AS (
			WITH t AS (
				SELECT j1.fk, NTILE(b) OVER (ORDER BY j1.!METRIC! - j2.!METRIC!) quint
				FROM jhu.!REGION! j1
				JOIN jhu.!REGION! j2 ON j1.fk = j2.fk
				WHERE j1.fk = ANY(gids) AND j1.date = d1 AND j2.date = d2
			)
			SELECT t.quint, ST_AsMVTGeom(r.geom, te) geom
			FROM regions.!REGION! r
			JOIN t ON r.gid = t.fk
			WHERE r.gid = ANY(gids) AND ST_Intersects(r.geom, te)
		) SELECT ST_AsMVT(mvtgeom.*) FROM mvtgeom
	);
END;
$$ LANGUAGE plpgsql;

/*
    database structure for maestro
*/

CREATE DATABASE dstil;

CREATE TABLE maestro_mac
	(
	mid bigserial NOT NULL,
	src_ip inet,
	src_mac macaddr,
	insert_time timestamp with time zone NOT NULL
	);

GRANT ALL PRIVILEGES ON maestro_mac TO ruby;
ALTER TABLE maestro_mac OWNER TO ruby;

CREATE TABLE maestro_reg
	(
	firstname varchar(18),
	lastname varchar(18),
	username varchar(7),
	devmake varchar(18),
	devmodel varchar(18),
	devmac macaddr,
	/* devprob varchar(100), */
	devagent text,
	reg_time timestamp with time zone NOT NULL
	);

GRANT ALL PRIVILEGES ON maestro_reg TO ruby;
ALTER TABLE maestro_reg OWNER TO ruby;

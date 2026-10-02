-- Runs once, when the postgres volume is created. One database per Magnolia instance:
-- the Jackrabbit schema (tables prefixed pm_*, version_*) must not be shared between author and public.
CREATE DATABASE magnolia_author;
CREATE DATABASE magnolia_public;

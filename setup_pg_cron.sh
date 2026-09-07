#!/bin/bash
apt-get update
apt-get install -y postgresql-18-cron
echo "shared_preload_libraries = 'pg_cron'" >> /var/lib/postgresql/18/docker/postgresql.conf
echo Restart PostgreSQL container to apply changes.
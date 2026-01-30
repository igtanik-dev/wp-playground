up:
	docker compose up -d

down:
	docker compose down

reset:
	docker compose down -v
	docker compose up -d

db-import:
	gunzip -c db/seed.sql.gz | docker compose exec -T mysql sh -lc 'mysql -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"'

db-export:
	docker compose exec -T mysql sh -lc 'mysqldump --no-tablespaces -u"$$MYSQL_USER" -p"$$MYSQL_PASSWORD" "$$MYSQL_DATABASE"' | gzip > db/seed.sql.gz


config:
	docker compose run --rm --user root wpcli wp config create \
	--dbname=wordpress \
	--dbuser=wp \
	--dbpass=wp \
	--dbhost=mysql \
	--skip-check \
	--allow-root \
	--force

install:
	docker compose run --rm wpcli wp core install \
	--url="http://localhost:8080" \
	--title="WP Blueprint" \
	--admin_user="admin" \
	--admin_password="admin" \
	--admin_email="admin@example.com" \
	--skip-email


setup:

	docker compose down
	docker compose up -d
	# permalink
	docker compose run --rm wpcli wp rewrite structure '/%postname%/' --hard

	# cleanup
	docker compose run --rm wpcli wp post delete 1 --force || true
	docker compose run --rm wpcli wp post delete 2 --force || true
	docker compose run --rm wpcli wp post delete 3 --force || true
	docker compose run --rm wpcli wp comment delete 1 --force || true
	docker compose run --rm wpcli wp plugin delete akismet || true
	docker compose run --rm wpcli wp plugin delete hello || true
	
	# discussion
	docker compose run --rm wpcli wp option update default_comment_status closed
	docker compose run --rm wpcli wp option update default_ping_status closed

	# media
	docker compose run --rm wpcli wp option update thumbnail_size_w 0
	docker compose run --rm wpcli wp option update thumbnail_size_h 0
	docker compose run --rm wpcli wp option update medium_size_w 0
	docker compose run --rm wpcli wp option update medium_size_h 0
	docker compose run --rm wpcli wp option update large_size_w 0
	docker compose run --rm wpcli wp option update large_size_h 0

	# timezone
	docker compose run --rm wpcli wp option update timezone_string Europe/London
	docker compose run --rm wpcli wp option update date_format 'd/m/Y'
	docker compose run --rm wpcli wp option update time_format 'H:i'

	# themes
	docker compose run --rm wpcli wp theme activate bricks
	docker compose run --rm wpcli wp theme activate bricks-child
	docker compose run --rm wpcli wp theme delete twentytwentytwo --force || true
	docker compose run --rm wpcli wp theme delete twentytwentythree --force || true
	docker compose run --rm wpcli wp theme delete twentytwentyfour --force || true


env:
	@test -f .env || cp .env.example .env

init:
	make env
	make up
	make config
	make install




demo-page:
	docker compose run --rm wpcli wp post create \
	--post_type=page \
	--post_title="DB Test Page" \
	--post_status=publish


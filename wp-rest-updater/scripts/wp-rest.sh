#!/usr/bin/env bash
# Thin wrapper over the WordPress REST API for pages and posts.
# Auth: Application Password stored in ~/.netrc for the site host (curl --netrc).
# Config: WP_REST_BASE (e.g. https://host/sub/wp-json), optional WP_REST_BACKUP_DIR.
set -euo pipefail

: "${WP_REST_BASE:?Set WP_REST_BASE, e.g. https://example.com/wp-json}"
backup_dir="${WP_REST_BACKUP_DIR:-${TMPDIR:-/tmp}/wp-rest-backups}"

api() { curl -sS --fail-with-body --netrc -H 'Content-Type: application/json' "$@"; }

usage() {
	cat <<'EOF'
Usage:
  wp-rest.sh whoami
  wp-rest.sh get <pages|posts> <id> <out-file>        save content.raw to out-file
  wp-rest.sh create <pages|posts> <title> <slug>      create a draft
  wp-rest.sh update <pages|posts> <id> <content-file> back up current content, then replace it
EOF
	exit 1
}

cmd="${1:-}"
[ -n "$cmd" ] || usage
shift

case "$cmd" in
	whoami)
		api "$WP_REST_BASE/wp/v2/users/me?context=edit&_fields=id,name,roles" | jq .
		;;
	get)
		[ $# -eq 3 ] || usage
		json=$(api "$WP_REST_BASE/wp/v2/$1/$2?context=edit&_fields=id,title,status,slug,modified,content") \
			|| { printf '%s\n' "$json" >&2; exit 1; }
		jq -j '.content.raw' <<< "$json" > "$3"
		jq '{id, title: .title.raw, status, slug, modified}' <<< "$json"
		;;
	create)
		[ $# -eq 3 ] || usage
		jq -n --arg title "$2" --arg slug "$3" '{title: $title, slug: $slug, status: "draft"}' \
			| api -X POST --data-binary @- "$WP_REST_BASE/wp/v2/$1?_fields=id,status,slug,link" \
			| jq .
		;;
	update)
		[ $# -eq 3 ] || usage
		mkdir -p "$backup_dir"
		backup="$backup_dir/$1-$2-$(date +%Y%m%d-%H%M%S).html"
		"$0" get "$1" "$2" "$backup" > /dev/null
		jq -Rs '{content: .}' "$3" \
			| api -X POST --data-binary @- "$WP_REST_BASE/wp/v2/$1/$2?_fields=id,status,modified" \
			| jq --arg backup "$backup" '. + {backup: $backup}'
		;;
	*)
		usage
		;;
esac

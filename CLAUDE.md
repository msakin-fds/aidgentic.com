# aidgentic.com — Claude Code guide

This project is a WordPress site hosted on SiteGround. Claude Code web
sessions are sandboxed and **cannot** make outbound HTTP requests to
`aidgentic.com` directly (confirmed: `403 host_not_allowed`). Use the
Supabase-proxied REST API method described below instead of trying to
`curl` the site.

## How to talk to the WordPress site

All WordPress operations go through a Supabase SQL function,
`public.wp_api(method, path, body)`, which is defined in
`.claude/sql/wp_api.sql`. The function uses Supabase's `http` extension
(not sandboxed) to hit the site's REST API with Basic Auth using a
WordPress Application Password.

```
SELECT public.wp_api('GET',  '/wp/v2/pages');
SELECT public.wp_api('GET',  '/wp/v2/posts?per_page=5');
SELECT public.wp_api('POST', '/wp/v2/posts',
                     '{"title":"Hello","status":"draft"}');
```

Shape of the result: `{ "status": <int>, "body": <jsonb> }`, or
`{ "error": "<message>" }` on failure.

## One-time Supabase setup

1. Create a Supabase project (any region) at
   <https://supabase.com/dashboard>.
2. Database -> Extensions -> enable `http` (under the `extensions`
   schema).
3. SQL Editor -> paste `.claude/sql/wp_api.sql`, replace
   `__WP_USER__` and `__WP_APP_PASSWORD__` (spaces removed), Run.
4. Smoke test: `SELECT public.wp_api('GET', '/') ->> 'status';` should
   return `200`.

## WordPress Application Password

Generated at `aidgentic.com/wp-admin` -> Users -> Profile ->
Application Passwords. Paste it into the `wp_api.sql` placeholder with
**no spaces**. Never commit it to the repo.

## Why SSH / WP-CLI is not the primary path

We also ship `.github/workflows/wp-cli.yml` for operations that the
REST API does not cover (e.g. transients, cron, some plugin commands).
That workflow runs on GitHub runners (network unrestricted) and SSHes
into SiteGround. For anything expressible as REST, prefer `wp_api()` —
it is faster and has no shell quoting pitfalls.

## Skills in this repo

- `.claude/skills/frontend-design/SKILL.md` — production-grade UI
  implementation (tokens, a11y, motion, performance).
- `.claude/skills/ux-ui-pro-max/SKILL.md` — end-to-end product design
  (heuristics, flows, IA, copy, design system foundations).

## Branches

All development lands on `main`, per project policy.

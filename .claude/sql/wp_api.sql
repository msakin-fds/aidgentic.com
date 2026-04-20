-- aidgentic.com WordPress REST proxy via Supabase
--
-- Deploy once on a Supabase project:
--   1. Supabase Dashboard -> Database -> Extensions -> enable `http`
--      (it lives under the `extensions` schema).
--   2. Supabase Dashboard -> SQL Editor -> paste this file -> Run.
--   3. Replace the two placeholders below before running:
--        __WP_USER__          -> WordPress admin username or email
--        __WP_APP_PASSWORD__  -> Application password WITH spaces removed
--
-- Usage from a Claude Code session with the Supabase MCP enabled:
--   SELECT public.wp_api('GET',  '/wp/v2/pages');
--   SELECT public.wp_api('GET',  '/wp/v2/posts?per_page=5');
--   SELECT public.wp_api('POST', '/wp/v2/posts', '{"title":"Hello","status":"draft"}');
--
-- Returns: jsonb { status: int, body: jsonb }  (or { error: text } on failure)

CREATE OR REPLACE FUNCTION public.wp_api(
  method text,
  path   text,
  body   text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  creds    text := '__WP_USER__:__WP_APP_PASSWORD__';
  base_url text := 'https://aidgentic.com/wp-json';
  req      extensions.http_request;
  res      extensions.http_response;
BEGIN
  req := ROW(
    method,
    base_url || path,
    ARRAY[
      extensions.http_header(
        'Authorization',
        'Basic ' || encode(convert_to(creds, 'UTF8'), 'base64')
      ),
      extensions.http_header('Accept',       'application/json'),
      extensions.http_header('Content-Type', 'application/json')
    ],
    'application/json',
    body
  )::extensions.http_request;

  SELECT * INTO res FROM extensions.http(req);

  RETURN jsonb_build_object(
    'status', res.status,
    'body',   res.content::jsonb
  );
EXCEPTION WHEN others THEN
  RETURN jsonb_build_object('error', SQLERRM);
END;
$$;

-- Optional: lock this down so only the service role can invoke it.
REVOKE ALL ON FUNCTION public.wp_api(text, text, text) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION public.wp_api(text, text, text) TO service_role;

-- Smoke test:
--   SELECT public.wp_api('GET', '/') ->> 'status';   -- expect "200"
--   SELECT public.wp_api('GET', '/wp/v2/users/me');  -- expect current user JSON

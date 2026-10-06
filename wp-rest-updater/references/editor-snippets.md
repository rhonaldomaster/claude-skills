# Editor snippets

Run these with Playwright `browser_evaluate` on a page where the block editor is loaded in the **local** site (e.g. `/wp-admin/post-new.php?post_type=page`). The editor uses the project's real registered blocks, so `serialize` produces the exact markup `save()` would.

Local and remote must run the same block code. If the remote is behind, deploy first or the saved markup will not match.

## Build blocks from a spec

Edit `spec` and run. `innerBlocks` nests children (e.g. `journey` with `journey-entry` items).

```js
() => {
  const { createBlock, serialize, parse } = wp.blocks;
  const spec = [
    { name: 'marymount-sombra/journey', attrs: { heading: 'Title' }, innerBlocks: [
      { name: 'marymount-sombra/journey-entry', attrs: { entryTitle: 'One', linkText: 'More', linkUrl: '/one/', image: { id: 1, url: 'https://...', alt: '' } } },
    ] },
  ];
  const build = (b) => createBlock(b.name, b.attrs || {}, (b.innerBlocks || []).map(build));
  const all = (bs) => bs.flatMap(b => [b, ...all(b.innerBlocks)]);
  const markup = serialize(spec.map(build));
  const invalid = all(parse(markup)).filter(b => !b.isValid).map(b => b.name);
  return { markup, invalid };
}
```

`invalid` must be empty. Attributes equal to their default are omitted from the comment; that is expected.

To get the markup into a file without copying it by hand, pass `filename` to `browser_evaluate` (it must be inside the Playwright output folder, e.g. `.playwright-mcp/built.json`), then `jq -j .markup .playwright-mcp/built.json > page.html`.

## Edit blocks in existing content

Paste `content.raw` (saved by `wp-rest.sh get`) as a JSON string literal, for example the output of `jq -Rs . file.html`.

```js
() => {
  const { serialize, parse } = wp.blocks;
  const raw = JSON.parse('<paste jq -Rs output here>');
  const all = (bs) => bs.flatMap(b => [b, ...all(b.innerBlocks)]);
  const blocks = parse(raw);
  const invalid = all(blocks).filter(b => !b.isValid).map(b => b.name);
  if (invalid.length) return { invalid }; // stop: do not edit content the editor already flags
  all(blocks).find(b => b.name === 'marymount-sombra/hero-tmw-sangre').attributes.heading = 'New heading';
  return { markup: serialize(blocks) };
}
```

Changing an attribute updates both the comment JSON and the saved HTML, so there is nothing to keep in sync by hand. Untouched blocks re-serialize byte-identical (checked on hero, journey with nested entries, a core paragraph and a dynamic faq). Always diff the result against the original before updating.

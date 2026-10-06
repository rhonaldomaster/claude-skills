# Editor snippets

Run these with Playwright `browser_evaluate` on a page where the block editor is loaded in the **local** site (e.g. `/wp-admin/post-new.php?post_type=page`). The editor uses the project's real registered blocks, so `serialize` produces the exact markup `save()` would.

Local and remote must run the same block code. If the remote is behind, deploy first or the saved markup will not match.

Replace the `<...>` placeholders with the project's block names and attributes (see each block's `block.json`).

## Build blocks from a spec

Edit `spec` and run. `innerBlocks` nests children (a parent block with child items).

```js
() => {
  const { createBlock, serialize, parse } = wp.blocks;
  const spec = [
    { name: '<namespace>/<parent-block>', attrs: { <attribute>: 'Title' }, innerBlocks: [
      { name: '<namespace>/<child-block>', attrs: { <attribute>: 'One', image: { id: 1, url: 'https://...', alt: '' } } },
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

To get the markup into a file without copying it by hand, pass `filename` to `browser_evaluate` (it must be inside the Playwright output folder, e.g. `.playwright-mcp/built.json`). Check `jq .invalid .playwright-mcp/built.json` is `[]`, then `jq -j .markup .playwright-mcp/built.json > page.html`.

## Edit blocks in existing content

Paste `content.raw` (saved by `wp-rest.sh get`) as the output of `jq -Rs . file.html`. That output is already a valid JS string literal, so do not wrap it in quotes or `JSON.parse`.

```js
() => {
  const { serialize, parse } = wp.blocks;
  const raw = <paste jq -Rs output here>;
  const all = (bs) => bs.flatMap(b => [b, ...all(b.innerBlocks)]);
  const blocks = parse(raw);
  const invalid = all(blocks).filter(b => !b.isValid).map(b => b.name);
  if (invalid.length) return { invalid }; // stop: do not edit content the editor already flags
  const target = all(blocks).find(b => b.name === '<namespace>/<block>');
  if (!target) return { notFound: '<namespace>/<block>' };
  target.attributes.<attribute> = 'New value';
  return { markup: serialize(blocks) };
}
```

Changing an attribute updates both the comment JSON and the saved HTML, so there is nothing to keep in sync by hand. Untouched blocks re-serialize unchanged in most cases (checked on a hero block, a parent with nested children, a core paragraph and a dynamic block). One known difference, seen on a real page: a literal non-breaking space (U+00A0) inside a rich-text value is written back as `&nbsp;`. It renders the same, but the line shows up in the diff even if you did not touch that block. Always diff the result against the original before updating.

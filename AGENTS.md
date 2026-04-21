# Documentation structure

- Keep `README.md` short and focused on project overview, installation, and contributor setup.
- Put usage guides and end-to-end examples in the GitHub wiki, following the existing `Example:-...` page style.
- Keep `values.schema.json` and generated `values.md` limited to fields the chart templates handle directly.
- When a value is passed through unchanged to Kubernetes, document that passthrough behavior, but do not restate nested Kubernetes API fields in the schema.

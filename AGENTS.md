# Repository instructions

## Transpara TLC workflow

For software changes in this transpara-ai repository, use the host-installed
`transpara-tlc` plugin's `tlc` skill. Default to Routine and escalate only under
its route rules. The canonical source is [transpara-ai/tlc](https://github.com/transpara-ai/tlc).

TLC is an external, unpinned developer dependency. Host maintainers install and
update it; repository configuration does not pin, install, enable, or copy the
workflow. Preserve the project-specific instructions and verification above.

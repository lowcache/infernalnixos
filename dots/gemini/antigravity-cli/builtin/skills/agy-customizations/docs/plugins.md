# Plugins

Plugins are namespaced, shareable bundles that package **Skills**, **Rules**,
**Hooks**, and **MCP Server Configurations** into a single deployable unit. They
are the recommended way to distribute complex, feature-rich customizations to
your team.

--------------------------------------------------------------------------------

## Directory Structure

A plugin must be contained within a subdirectory of a `plugins/` folder in a
customization root (e.g., `.agents/plugins/`).

```text
plugins/<plugin_name>/
├── plugin.json       # Required: Manifest file
├── mcp_config.json   # Optional: MCP servers exposed by the plugin
├── hooks.json        # Optional: Lifecycle hooks run by the plugin
├── rules/            # Optional: Rules applied when plugin is active
│   └── *.md
└── skills/           # Optional: Skills exposed by the plugin
    └── <skill_name>/
        └── SKILL.md
```

--------------------------------------------------------------------------------

## Manifest (`plugin.json`)

The `plugin.json` file serves as the marker declaring the directory as a plugin.

```json
{
  "name": "team-developer-kit"
}
```

*   **`name`** (string, optional): The display name of the plugin. If omitted,
    it defaults to the directory name.

--------------------------------------------------------------------------------

## How Plugins Work

When a plugin is discovered and enabled:

1.  **Automatic Ingestion**: All skills, rules, hooks, and MCP servers defined
    within the plugin's directory structure are automatically loaded.
2.  **Namespacing**: Tools and skills exposed by the plugin are namespaced if
    necessary to prevent collisions with other customizations.
3.  **Lifecycle Scoping**:
    *   **Hooks** defined in `plugins/<name>/hooks.json` are registered and run
        during the agent's lifecycle.
    *   **MCP Servers** defined in `plugins/<name>/mcp_config.json` are
        launched, and their tools are made available.
    *   **Rules** in `plugins/<name>/rules/` are merged into the active rule
        set.

## Enabling Plugins

Plugins can be discovered automatically if placed in standard customization
roots, or they can be explicitly registered and enabled using `plugins.json`.

*   See the [JSON Configurations Guide](./json_configs.md) for details on how to
    use `plugins.json` to enable specific plugins or inherit them from shared
    paths.

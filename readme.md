# Index File Generator Plugin

This Neovim plugin automatically generates index files (`index.ts` or `index.js`) for your project directories. It scans the specified directory and creates an index file that exports all TypeScript, JavaScript, or JSX/TSX/Vue files in the directory.

https://github.com/try-to-fly/create-index.nvim/assets/16008258/1a510998-25e3-414e-a08d-566992c2e9fe

## Features

- Automatically detects the project root by locating the nearest `package.json` file.
- Supports `oil://` paths for directories.
- Generates `index.ts` if any `.ts` or `.tsx` files are found, otherwise generates `index.js`.
- If the `index.js` or `index.ts` file already exists, it will update only the export statements that correspond to the current directory, preserving any other export statements or custom logic in the file.

## Installation

Use your preferred plugin manager to install the plugin. For example, using `Lazy`:

```lua
{
  "try-to-fly/create-index.nvim",
  config = function()
    require("index_creator").setup()
  end,
}
```

## Usage

### Command

Run the following command in Neovim to create an index file in the current directory:

```vim
:lua require('index_creator').create_index()
```

### How It Works

1. The plugin retrieves the current file or directory path.
2. If the path starts with `oil://`, the path after `oil://` is used as the target directory.
3. If the current path is a file, the directory containing the file is used as the target directory.
4. If the current path is a directory, it is used as the target directory.
5. The plugin scans the target directory for `.ts`, `.tsx`, `.js`, `.vue`, and `.jsx` files.
6. If any `.ts` or `.tsx` files are found, `index.ts` is generated; otherwise, `index.js` is generated.
7. If an `index.js` or `index.ts` file already exists, only the export statements corresponding to the current directory are updated, preserving other content in the file.
8. The index file exports all found files and folders.

## Example

Given the following directory structure:

```
components/
  │
  ├── Card.tsx
  ├── Filter.tsx
  ├── Header.tsx
```

Running the command will create an `index.ts` file with the following content:

```typescript
export * from "./Card";
export * from "./Filter";
export * from "./Header";
```

If the `index.ts` file already exists and contains other export statements, those statements will be preserved, and only the export statements for the current directory will be updated.

## License

This plugin is open-sourced software licensed under the [MIT license](LICENSE).




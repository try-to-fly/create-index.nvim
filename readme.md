# Index File Generator Plugin

This Neovim plugin automatically generates index files (`index.ts` or `index.js`) for your project directories. It scans the specified directory and creates an index file that exports all TypeScript, JavaScript, or JSX/TSX files in the directory.

## Features

- Automatically detects the project root by locating the nearest `package.json` file.
- Supports `oil://` paths for directories.
- Generates `index.ts` if any `.ts` or `.tsx` files are found, otherwise generates `index.js`.

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
:lua require('index-file-generator').create_index()
```

### How It Works

1. The plugin retrieves the current file or directory path.
2. If the path starts with `oil://`, the path after `oil://` is used as the target directory.
3. If the current path is a file, the directory containing the file is used as the target directory.
4. If the current path is a directory, it is used as the target directory.
5. The plugin scans the target directory for `.ts`, `.tsx`, `.js`, and `.jsx` files.
6. If any `.ts` or `.tsx` files are found, `index.ts` is generated; otherwise, `index.js` is generated.
7. The index file exports all found files and folders.

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

## License

This plugin is open-sourced software licensed under the [MIT license](LICENSE).

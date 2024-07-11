local M = {}

local function get_target_folder()
	local current_path = vim.fn.expand("%:p")

	if current_path:match("^oil://") then
		local oil_path = current_path:sub(7)
		return oil_path
	end

	if vim.fn.filereadable(current_path) == 1 then
		local folder_path = vim.fn.fnamemodify(current_path, ":h")
		return folder_path
	end

	if vim.fn.isdirectory(current_path) == 1 then
		return current_path
	end

	local cwd = vim.fn.getcwd()
	return cwd
end

local function find_project_root(path)
	local current_path = vim.fn.fnamemodify(path, ":p:h")
	while current_path ~= "/" and current_path ~= "" do
		if vim.fn.filereadable(current_path .. "/package.json") == 1 then
			return current_path
		end
		local parent_path = vim.fn.fnamemodify(current_path .. "/..", ":p:h")
		if parent_path == current_path then
			break
		end
		current_path = parent_path
	end
	return nil
end

local function read_directory(path)
	local files = vim.fn.readdir(path)
	return files
end

local function file_exists(path)
	return vim.fn.filereadable(path) == 1
end

local function dir_exists(path)
	return vim.fn.isdirectory(path) == 1
end

local function is_module_type(project_root)
	local package_json_path = project_root .. "/package.json"
	local package_json = vim.fn.json_decode(table.concat(vim.fn.readfile(package_json_path), "\n"))
	local is_module = package_json and package_json.type == "module"
	return is_module
end

local function is_ts_project(project_root)
	return file_exists(project_root .. "/tsconfig.json")
end

local function to_camel_case(str)
	return str:gsub("(%a)(%a*)", function(first, rest)
		return first:upper() .. rest:lower()
	end):gsub("[^%w]", "")
end

local function generate_exports_content(path, files, is_module, is_ts)
	local index_file_content = {}

	for _, file in ipairs(files) do
		local file_path = path .. "/" .. file
		if file:match("%.tsx?$") or file:match("%.jsx?$") or file:match("%.js$") then
			-- 忽略现有的 index 文件
			if file ~= "index.ts" and file ~= "index.js" then
				table.insert(
					index_file_content,
					"export * from './" .. file:gsub("%.%w+$", "") .. (is_module and ".js" or "") .. "'"
				)
			end
		elseif file:match("%.vue$") then
			local filename = file:gsub("%.vue$", "")
			local camel_case_name = to_camel_case(filename)
			table.insert(index_file_content, "export { default as " .. camel_case_name .. " } from './" .. file .. "'")
		elseif
			dir_exists(file_path) and (file_exists(file_path .. "/index.js") or file_exists(file_path .. "/index.ts"))
		then
			table.insert(index_file_content, "export * from './" .. file .. (is_module and "/index.js" or "") .. "'")
		end
	end

	return index_file_content
end

local function parse_treesitter(content, lang)
	local parser = vim.treesitter.get_parser(0, lang)
	local tree = parser:parse()[1]
	return tree:root()
end

local function extract_exports(root, src)
	local query = vim.treesitter.query.parse(
		"javascript",
		[[
		(export_statement) @export
		(export_clause) @export
	]]
	)

	local exports = {}
	for id, node, metadata in query:iter_captures(root, src, 0, -1) do
		if query.captures[id] == "export" then
			table.insert(exports, node)
		end
	end

	return exports
end

local function update_index_file(path, new_exports, is_module, is_ts)
	local index_file_path = path .. (is_ts and "/index.ts" or "/index.js")
	local existing_content = {}

	if file_exists(index_file_path) then
		existing_content = vim.fn.readfile(index_file_path)
	end

	local ext = is_ts and "typescript" or "javascript"
	local root = parse_treesitter(table.concat(existing_content, "\n"), ext)
	local existing_exports = extract_exports(root, index_file_path)

	local final_content = {}
	local in_export_section = false

	-- 复制现有内容
	for _, line in ipairs(existing_content) do
		table.insert(final_content, line)
	end

	-- 替换目录下的导出语句
	for _, export_node in ipairs(existing_exports) do
		local text = vim.treesitter.get_node_text(export_node, index_file_path)
		if text:match("^export%s+%*%s+from%s+'./") then
			in_export_section = true
			for _, export_line in ipairs(new_exports) do
				table.insert(final_content, export_line)
			end
		else
			table.insert(final_content, text)
		end
	end

	if not in_export_section then
		for _, export_line in ipairs(new_exports) do
			table.insert(final_content, export_line)
		end
	end

	vim.fn.writefile(final_content, index_file_path)
end

function M.create_index()
	local target_folder = get_target_folder()
	local files = read_directory(target_folder)
	local filtered_files = {}

	for _, file in ipairs(files) do
		if
			file:match("%.tsx?$")
			or file:match("%.jsx?$")
			or file:match("%.js$")
			or file:match("%.vue$")
			or dir_exists(target_folder .. "/" .. file)
		then
			-- 忽略现有的 index 文件
			if file ~= "index.ts" and file ~= "index.js" then
				table.insert(filtered_files, file)
			end
		end
	end

	if #filtered_files == 0 then
		return
	end

	local project_root = find_project_root(target_folder)
	if not project_root then
		return
	end

	local is_module = is_module_type(project_root)
	local is_ts = is_ts_project(project_root)
	local new_exports = generate_exports_content(target_folder, filtered_files, is_module, is_ts)
	update_index_file(target_folder, new_exports, is_module, is_ts)
	-- 刷新当前active下的buffer
	vim.cmd("e")
end

M.setup = function()
	vim.api.nvim_create_user_command("CreateIndex", function()
		M.create_index()
	end, {})
end

return M

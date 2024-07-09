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

local function create_index_file(path, files, is_module, is_ts)
	local index_file_path = path .. (is_ts and "/index.ts" or "/index.js")
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
			table.insert(index_file_content, "export * from './" .. file .. (is_module and ".js" or "") .. "'")
		end
	end

	vim.fn.writefile(index_file_content, index_file_path)
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
	create_index_file(target_folder, filtered_files, is_module, is_ts)
end

M.setup = function()
	vim.api.nvim_create_user_command("CreateIndex", function()
		M.create_index()
	end, {})
end

return M

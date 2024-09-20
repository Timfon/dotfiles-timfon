vim.g.firenvim_config = {
  localSettings = {
    ['.*'] = { takeover = 'never' }
  }
}

vim.g.python3_host_prog = '/Users/timothyfong/.pyenv/shims/python'
-- vim.g.python3_host_prog = "~/Lang/GlobalVenv/bin/python3.9"
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)


vim.wo.relativenumber = true
vim.opt.termguicolors = true

vim.g.mapleader = " "
vim.g.maplocalleader = ","
--
-- local severe_ns = vim.api.nvim_create_namespace("severe-diagnostics")
--
-- local function max_diagnostic(callback)
-- 	return function(_, bufnr, diagnostics, opts)
-- 		local line_to_diagnostic = {}
-- 		for _, d in ipairs(diagnostics) do
-- 			local m = line_to_diagnostic[d.lnum]
-- 			if not m or d.severity < m.severity then
-- 				line_to_diagnostic[d.lnum] = d
-- 			end
-- 		end
-- 		callback(severe_ns, bufnr, vim.tbl_values(line_to_diagnostic), opts)
-- 	end
-- end
--
-- local signs_handler = vim.diagnostic.handlers.signs
-- vim.diagnostic.handlers.signs = vim.tbl_extend("force", signs_handler, {
-- 	show = max_diagnostic(signs_handler.show),
-- 	hide = function(_, bufnr)
-- 		signs_handler.hide(severe_ns, bufnr)
-- 	end,
-- })
--
vim.diagnostic.config({
	underline = false,
	virtual_text = false,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.HINT] = "",
			[vim.diagnostic.severity.INFO] = "",
		},
	},
	float = {
		header = "",
		max_width = math.min(math.floor(vim.o.columns * 0.7), 100),
		max_height = math.min(math.floor(vim.o.lines * 0.3), 30),
	},
})

vim.filetype.add({
	extension = {
		typ = "typst",
		v = "coq",
		kk = "koka",
		rkt = "racket",
		pl = "prolog",
		mly = "menhir",
	},
	filename = {
		["yabairc"] = "sh",
	},
})



-- Function to change the local directory to the current buffer's directory
local function change_local_directory()
  local bufname = vim.fn.bufname()
  local buftype = vim.bo.buftype

  -- Only execute if the buffer has a valid file name and is not a terminal buffer
  if bufname ~= "" and buftype == "" then
    local file_dir = vim.fn.expand('%:h')  -- Get the directory of the current file
    vim.cmd("lcd " .. file_dir)
    local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
    

    if git_root and git_root ~= "" and vim.fn.isdirectory(git_root) == 1 then
      vim.cmd("lcd " .. git_root)
    end
  end
end

-- Create an autocommand that runs the function on BufEnter
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.*",
  callback = change_local_directory
})

-- Map the function to <C-`>
vim.api.nvim_set_keymap('n', '<C-`>', [[:lua change_local_directory()<CR>]], { noremap = true, silent = true })

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local bufopts = { noremap = true, silent = true, buffer = ev.buf }
		vim.keymap.set("n", "[d", require("delimited").goto_prev, bufopts)
    vim.keymap.set('n', "<F4>", ':!python %<CR>')
		vim.keymap.set("n", "]d", require("delimited").goto_next, bufopts)
		vim.keymap.set("n", "[D", function()
			require("delimited").goto_prev({ severity = vim.diagnostic.severity.ERROR })
		end, bufopts)
		vim.keymap.set("n", "]D", function()
			require("delimited").goto_next({ severity = vim.diagnostic.severity.ERROR })
		end, bufopts)
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
		vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
		vim.keymap.set("n", "<leader>sig", vim.lsp.buf.signature_help, bufopts)
		vim.keymap.set("n", "<leader>wsa", vim.lsp.buf.add_workspace_folder, bufopts)
		vim.keymap.set("n", "<leader>wsr", vim.lsp.buf.remove_workspace_folder, bufopts)
		vim.keymap.set("n", "<leader>wsl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, bufopts)
		vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, bufopts)
		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
		vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
		vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, bufopts)
	end,
})
--Be able to expand large screen size = 30, and automatically switch focus to the terminal window
local function check_file_size_and_open_with_less()
    local file = vim.fn.expand('%:p')
    if vim.fn.getfsize(file) > 512 * 1024 then
        -- Open the file with less in a new terminal
        vim.cmd('enew')  -- Open a new empty buffer
        vim.cmd('ToggleTerm size=100')  -- Open a new terminal window
        vim.cmd('TermExec cmd="less ' .. file .. '"')  -- Open file with less in toggleterm
        
        -- Use a timer to ensure the terminal is ready
        vim.defer_fn(function()
            vim.cmd('wincmd j')  -- Move to the window below
            vim.cmd('startinsert')  -- Start terminal mode
        end, 100)  -- Wait 100ms before executing
    end
end

vim.api.nvim_create_augroup('BigFileOpenWithLess', { clear = true })
vim.api.nvim_create_autocmd({ 'BufReadPre', 'FileReadPre' }, {
    group = 'BigFileOpenWithLess',
    pattern = '*',
    callback = check_file_size_and_open_with_less,
})

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*.json",
  callback = function()
    vim.api.nvim_command("%!jq .")
  end
})
require("lazy").setup({
	{
		"https://github.com/rose-pine/neovim",
		lazy = false,
		priority = 1000,
		config = function()
			require("rose-pine").setup({
				dark_variant = "moon",
				disable_italics = false,
				styles = {
					bold = true,
					italic = true,
				},
				highlight_groups = {
					LineNr = { fg = "highlight_high" },
					CursorLineNr = { fg = "muted", inherit = false },
					StatusLine = { fg = "love", bg = "#f5e9e3" },
					MatchParen = { bg = "#f6ebdd", inherit = false },
					DiagnosticVirtualTextError = { bg = "#f5e9e3" },
					DiagnosticVirtualTextWarn = { bg = "#f6ebdd" },
					DiagnosticVirtualTextInfo = { bg = "#eaeae5" },
					DiagnosticVirtualTextHint = { bg = "#efe8e6" },
					EndOfBuffer = { fg = "highlight_med" },
					WinSeparator = { fg = "highlight_med" },
					IblScope = { fg = "highlight_med" },
					IblIndent = { fg = "highlight_low" },
					CursorLine = { bg = "highlight_low" },
					TelescopeSelectionCaret = { fg = "love", bg = "highlight_med" },
					TelescopeMultiSelection = { fg = "text", bg = "highlight_high" },
					TelescopeTitle = { fg = "base", bg = "love" },
					TelescopePromptTitle = { fg = "base", bg = "pine" },
					TelescopePreviewTitle = { fg = "base", bg = "iris" },
					Todo = { fg = "love", bg = "love", blend = 1 },
					TelescopePromptNormal = { fg = "text", bg = "surface" },
					TelescopePromptBorder = { fg = "surface", bg = "surface" },
					LuaLineDiffAdd = { fg = "#56949f", bg = "#faf4ed" },
					LuaLineDiffChange = { fg = "#d7827e", bg = "#faf4ed" },
					CoqtailChecked = { bg = "#eaeae5" },
					CoqtailSent = { bg = "#f2e9e1" },
					DiffAdd = { bg = "#bacfc4", inherit = false },
					DiffDelete = { bg = "#dbb6b4", inherit = false },
					GitSignsAdd = { fg = "#bacfc4" },
					GitSignsChange = { fg = "#e6d2c1" },
					GitSignsDelete = { fg = "#dbb6b4" },
					DelimitedError = { fg = "love", bg = "#EDDAD8", inherit = false },
					DelimitedWarn = { fg = "gold", bg = "#F7E4CB", inherit = false },
					DelimitedInfo = { fg = "foam", bg = "#DCE3DF", inherit = false },
					DelimitedHint = { fg = "iris", bg = "#E7DEE1", inherit = false },
					CopilotSuggestion = { fg = "highlight_high" },
				},
			})
			require("adaptive")
			vim.cmd([[colorscheme rose-pine-dawn]])
		end,
	},
  {
  "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig", 
      "mfussenegger/nvim-dap", "mfussenegger/nvim-dap-python", --optional
      { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
    },
  lazy = false,
  branch = "regexp", -- This is the regexp branch, use this for the new version
  config = function()
      require("venv-selector").setup()
    end,
    keys = {
      { ",v", "<cmd>VenvSelect<cr>" },
    },
},
{
    "williamboman/mason.nvim",
    config = function()
        require("mason").setup()
    end
},
{ 'echasnovski/mini.nvim', version = '*' },
{ 'fatih/vim-go', version = "*"},
{'tpope/vim-pathogen', version = "*"},
{'junegunn/vim-plug', version = "*"},
{'Shougo/neobundle.vim', version = "*"},
{'gmarik/vundle', version = "*"},

{ 'echasnovski/mini.icons', version = false },
{
  "LunarVim/bigfile.nvim",
},
{
    "williamboman/mason.nvim"
},
{
   "amitds1997/remote-nvim.nvim",
   version = "*", -- Pin to GitHub releases
   dependencies = {
       "nvim-lua/plenary.nvim", -- For standard functions
       "MunifTanjim/nui.nvim", -- To build the plugin UI
       "nvim-telescope/telescope.nvim", -- For picking b/w different remote methods
   },
   config = true,
},
{
	"goolord/alpha-nvim",
	event = "VimEnter",
	dependencies = { "RchrdAriza/nvim-web-devicons" },
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		local time = os.date("%H:%M")
		local date = os.date("%a %d %b")
		local v = vim.version()
		local version = " v" .. v.major .. "." .. v.minor .. "." .. v.patch

		-- Set header
		dashboard.section.header.val = {
  "", 
  "                          !5?.                         ", 
  "               .^!!!^:.    .#@B!    .                  ", 
  "               ..~Y&@@@&P.  ^@@@&^  PP                 ", 
  "             ....   J@@#:   Y@@@&B. J@B                ", 
  "        .!P&@@@@@7   &@&!~7B@@@~   .&@@5               ", 
  "       .~!~!?5#@@&J?B@@@@@@@@@@G!~J@@@@& :^                  New file         n ", 
  "         :?G.  ?@@@@@@@@&&&@@@@@@@@@G~~^ #P            ", 
  "       7&@@@#YP&@@@@#?:    .^Y&@@@@@J..~&@Y             󰮗     Find file        f ", 
  "     .G#?^:~#@@@@@P:  .~77~.  .P@@@@@@@@@@: ^            ", 
  "     :: 7~..Y@@@@7  :B@@@@@@7   #@@@@@Y.::.B7                File Explorer    e     ", 
  "       #@@@@@@@@Y  .@@@G!~J@#   G@@@@@B77P@&           ", 
  "      P&~..^@@@@^  7@@&    ?.  ~@@@@@@@@@@@.                 Recent           r       ", 
  "      7 :^:?@@@@J  :@@@P^.  .~G@@@@@@@@@@&.            ", 
  "        #@@BG&@@@^  ~&@@@@@@@@@@@@@@@@@@5                    Configuration    c        ", 
  "        &&.  .@@@@!   7&@@@@@@@@@@@@@@G:             ", 
  "        ?^ BB&@@@@@G:   :7G&@@@@@@@@5:                  󱘞     Ripgrep          R  ", 
  "           5@5...!&@@B!.    .^7YBB7.                   ", 
  "            !.    :@@@@@G?^.                            󰗼     Quit             q    ", 
  "          :^.....~#@@@@@@@@Y.                          ", 
  "           :7YG#@@@@@@&GJ^.                            ", 
  ""
}
-- only for footer
		function centerText(text, width)
			local totalPadding = width - #text
			local leftPadding = math.floor(totalPadding / 2)
			local rightPadding = totalPadding - leftPadding
			return string.rep(" ", leftPadding) .. text .. string.rep(" ", rightPadding)
		end

		dashboard.section.footer.val = {
			centerText("glhf", 50),
			-- centerText("NvimOnMy_Way❤️", 50),
			-- " ",
			centerText(date, 50),
			centerText(time, 50),
			centerText(version, 50),
		}


	dashboard.section.buttons.val = {}

-- Set up keymaps for the functionality
vim.api.nvim_create_autocmd("FileType", {
  pattern = "alpha",
  callback = function()
    vim.keymap.set("n", "n", ":ene <BAR> startinsert <CR>", { buffer = true, silent = true })
    vim.keymap.set("n", "f", ":cd $HOME | Telescope find_files<CR>", { buffer = true, silent = true })
    vim.keymap.set("n", "e", ":cd $HOME | :NvimTreeOpen<CR>", { buffer = true, silent = true })
    vim.keymap.set("n", "r", ":Telescope oldfiles<CR>", { buffer = true, silent = true })
    vim.keymap.set("n", "c", ":e ~/.config/nvim/init.lua<CR>", { buffer = true, silent = true })
    vim.keymap.set("n", "R", ":Telescope live_grep<CR>", { buffer = true, silent = true })
    vim.keymap.set("n", "q", ":qa<CR>", { buffer = true, silent = true })
  end,
})
		-- Send config to alpha
		alpha.setup(dashboard.opts)

		-- Disable folding on alpha buffer
		vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
	end,
}, 

{
        'numirias/semshi',
        run = ':UpdateRemotePlugins',  -- This step is necessary to register semshi as a remote plugin
        ft = 'python'  -- Optional: Load the plugin only when editing Python files
    },



{

		"https://github.com/sainnhe/everforest",
		lazy = false,
		priority = 1000,
		config = function()
			vim.api.nvim_create_autocmd({ "ColorScheme" }, {
				pattern = { "everforest" },
				callback = function(_ev)
					vim.cmd([[
          hi def CoqtailChecked guibg=#425047
          hi def CoqtailSent guibg=#343f44
          hi def EphemeralError guibg=#eb6f92
          hi def EphemeralWarn guibg=#f6c177
          hi def EphemeralInfo guibg=#9ccfd8
          hi def EphemeralHint guibg=#c4a7e7
          ]])
				end,
			})
			vim.g.everforest_background = "soft"
			vim.g.everforest_better_performance = 1
		end,
	},
	"nvim-lua/plenary.nvim",
	{
		"https://github.com/nvim-treesitter/nvim-treesitter",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
        'markdown',
        'markdown_inline',
        'tsx',
        'typescript',
        'php',
        'json',
        'yaml',
        'css',
        'scss',
        'html',
        'javascript',
        'lua',
	'luadoc',
        'vim',
        'vimdoc',
        'jsdoc',
        'graphql',
        'bash',
        'prisma',
        'svelte',
        'sql',
        'regex',
      },
				highlight = { enable = true },
        indent = { enable = false },
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							-- You can use the capture groups defined in textobjects.scm
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["aa"] = "@parameter.outer",
							["ia"] = "@parameter.inner",
						},
					},
				},
			})
			local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
			parser_config.koka = {
				install_info = {
					url = "https://github.com/mtoohey31/tree-sitter-koka", -- local path or git repo
					files = { "src/parser.c", "src/scanner.c" },
					branch = "main",
					generate_requires_npm = false,
					requires_generate_from_grammar = true,
				},
				filetype = "koka", -- if filetype does not match the parser name
			}
      vim.keymap.set('n', "<C-e>", ':NvimTreeOpen<CR>')
		end,
	},
	{ "JoosepAlviste/nvim-ts-context-commentstring" },
	{
		"https://github.com/numToStr/Comment.nvim",
		opts = function()
			return { pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook() }
		end,
	},
	{
		"https://github.com/kylechui/nvim-surround",
		opts = {
			indent_lines = false,
		},
	},
	{
		"norcalli/nvim-colorizer.lua",
		config = function()
			require("colorizer").setup(nil, { css = true })
		end,
	},
	"https://github.com/romainl/vim-cool",
	{
		"mizlan/iswap.nvim",
		opts = {
			debug = true,
			move_cursor = true,
		},
		config = function()
		end,
	},
	-- { 'https://github.com/IndianBoy42/iswap.nvim', branch = 'expand_key' },
	"https://github.com/tpope/vim-fugitive",
	{
		"NeogitOrg/neogit",
		branch = "master",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = true,
	},
	{
		"luukvbaal/statuscol.nvim",
		config = function()
			local builtin = require("statuscol.builtin")
			require("statuscol").setup({
				segments = {
					{ text = { " " } },
					{ sign = { namespace = { ".*diagnostic/signs" }, colwidth = 2, auto = false } },
					{ text = { " " } },
					{ text = { builtin.lnumfunc }, click = "v:lua.ScLa" },
					{ text = { " " } },
					{ sign = { namespace = { "gitsigns" }, maxwidth = 2, colwidth = 1, auto = false } },
				},
			})
		end,
	},
	{
		"https://github.com/lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup({
				on_attach = function()
					local gs = package.loaded.gitsigns
					vim.keymap.set("n", "<leader>sh", gs.stage_hunk, { desc = "stage hunk" })
					vim.keymap.set("v", "<leader>sh", function()
						gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
					end, { desc = "stage selected" })
					vim.keymap.set("n", "<leader>sb", gs.stage_buffer, { desc = "stage buffer" })
					vim.keymap.set("n", "<leader>rh", "<Cmd>Gitsigns reset_hunk<CR>", { desc = "reset hunk" })
					vim.keymap.set("n", "]h", "<cmd>Gitsigns next_hunk<cr>", { desc = "next hunk" })
					vim.keymap.set("n", "[h", "<cmd>Gitsigns prev_hunk<cr>", { desc = "previous hunk" })
					vim.keymap.set(
						"n",
						"<leader>phi",
						"<cmd>Gitsigns preview_hunk_inline<cr>",
						{ desc = "preview hunk inline" }
					)
					vim.keymap.set(
						"n",
						"<leader>pho",
						"<cmd>Gitsigns preview_hunk<cr>",
						{ desc = "preview hunk overlay" }
					)
				end,
			})
		end,
	},
	{
		"https://github.com/nvim-treesitter/nvim-treesitter-context",
		config = function()
			require("treesitter-context").setup({
				enable = false,
				line_numbers = false,
			})
		end,
	},
	{
		"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
		config = function()
			require("nvim-treesitter.configs").setup({})
		end,
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && npm install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},

{
    'akinsho/toggleterm.nvim',
    version = "*", -- Optional: Use '*' to match any tag version
    config = function()
        require('toggleterm').setup({
            size = 10,
            open_mapping = [[<C-`>]],
            hide_numbers = true,
            shade_filetypes = {},
            shade_terminals = true,
            shading_factor = 2,
            start_in_insert = true,
            insert_mappings = true,
            persist_size = true,
            direction = "horizontal",
            close_on_exit = true,
            shell = vim.o.shell,
            dir = "git_dir",
            float_opts = {
                border = "curved",
                winblend = 0,
                highlights = {
                    border = "Normal",
                    background = "Normal",
                },
            },
        })
        --
        -- Set up mappings for multiple terminals
        vim.api.nvim_set_keymap('t', '`', '<C-\\><C-n>', { noremap = true, silent = true })

        
        vim.api.nvim_set_keymap('n', '<C-1>', '<Cmd>1ToggleTerm<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<C-2>', '<Cmd>2ToggleTerm<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<C-3>', '<Cmd>3ToggleTerm<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<C-4>', '<Cmd>4ToggleTerm<CR>', { noremap = true, silent = true })
                                          
        vim.api.nvim_set_keymap('t', '<C-1>', '<Cmd>1ToggleTerm<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('t', '<C-2>', '<Cmd>2ToggleTerm<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('t', '<C-3>', '<Cmd>3ToggleTerm<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('t', '<C-4>', '<Cmd>4ToggleTerm<CR>', { noremap = true, silent = true })



        vim.api.nvim_set_keymap('i', '<C-t>1', '<Esc><Cmd>1ToggleTerm<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('i', '<C-t>2', '<Esc><Cmd>2ToggleTerm<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('i', '<C-t>3', '<Esc><Cmd>3ToggleTerm<CR>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('i', '<C-t>4', '<Esc><Cmd>4ToggleTerm<CR>', { noremap = true, silent = true })
        -- Terminal mode mappings for window navigation
        vim.api.nvim_set_keymap('t', '<C-w>h', '<C-\\><C-n><C-w>h', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('t', '<C-w>j', '<C-\\><C-n><C-w>j', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('t', '<C-w>k', '<C-\\><C-n><C-w>k', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('t', '<C-w>l', '<C-\\><C-n><C-w>l', { noremap = true, silent = true })
    end
},
{
		"https://github.com/mizlan/delimited.nvim.git",
		opts = {
			pre = function()
				vim.cmd([[IBLDisable]])
			end,
			post = function()
				vim.cmd([[IBLEnable]])
			end,
		},
		config = function()
		end,
	},
	"https://github.com/nvim-treesitter/playground",
	"https://github.com/stevearc/dressing.nvim",
	{
		"https://github.com/hrsh7th/nvim-cmp",
		config = function()
			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-1),
					["<C-f>"] = cmp.mapping.scroll_docs(1),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<C-y>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
				}),
				sources = cmp.config.sources({
					{ name = "luasnip" },
					{ name = "nvim_lsp" },
					{ name = "nvim_lsp_signature_help" },
					{
						name = "buffer",
						option = {
							get_bufnrs = function()
								return vim.api.nvim_list_bufs()
							end,
						},
					},
					{ name = "conjure" },
				}),
			})
		end,
	},
	"hrsh7th/cmp-nvim-lsp",
	"https://github.com/hrsh7th/cmp-nvim-lsp-signature-help",
	"https://github.com/PaterJason/cmp-conjure",
	{
		"https://github.com/nvim-telescope/telescope.nvim",
		lazy = false,
		init = function()
			vim.keymap.set("n", "<Leader>ff", "<Cmd>Telescope find_files<CR>", { desc = "find file" })
			vim.keymap.set("n", "<Leader>fr", "<Cmd>Recent<CR>", { desc = "find frecent file" })
			vim.keymap.set("n", "<Leader>fo", "<Cmd>Telescope oldfiles<CR>", { desc = "find recent file" })
			vim.keymap.set("n", "<Leader>,", "<Cmd>Telescope buffers<CR>", { desc = "switch to buffer" })
			vim.keymap.set("n", [[<Leader>']], "<Cmd>Telescope resume<CR>", { desc = "resume previous search" })
			vim.keymap.set("n", [[<Leader>sp]], "<Cmd>Telescope live_grep_args<CR>", { desc = "ripgrep" })
			vim.keymap.set("n", "<Leader>gg", "<Cmd>0Git<CR>", { desc = "fugitive" })
			vim.keymap.set("n", "<Leader>hh", "<Cmd>Telescope help_tags<CR>", { desc = "help" })
		end,
		config = function()
			local actions = require("telescope.actions")
			local lga_actions = require("telescope-live-grep-args.actions")
			require("telescope").setup({
				defaults = {
					mappings = {
						i = {
							["<Down>"] = actions.cycle_history_next,
							["<Up>"] = actions.cycle_history_prev,
						},
					},
					history = {
						cycle_wrap = true,
					},
					path_display = { absolute = true },
					prompt_prefix = "   ",
					selection_caret = "  ",
					entry_prefix = "  ",
				},
				pickers = {
					buffers = {
						previewer = false,
						theme = "ivy",
						layout_config = {
							height = 0.5,
						},
						mappings = {
							i = {
								["<C-k>"] = actions.delete_buffer,
							},
						},
					},
					oldfiles = {
						previewer = false,
						theme = "ivy",
						layout_config = {
							height = 0.5,
						},
					},
					find_files = {
						hidden = true,
						find_command = { "rg", "--files", "--iglob", "!.git", "--hidden" },
						previewer = false,
						theme = "ivy",
						layout_config = {
							height = 0.5,
						},
					},
					frecency = {
						theme = "ivy",
					},
				},
				extensions = {
					file_browser = {
						theme = "ivy",
						hijack_netrw = true,
					},
					frecency = {
						show_scores = false,
						auto_validate = false,
					},
					live_grep_args = {
						auto_quoting = true,
						mappings = {
							i = {
								["<C-k>"] = lga_actions.quote_prompt(),
								["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
							},
						},
						theme = "ivy", -- use dropdown theme
						layout_config = {
							height = 0.5,
						},
					},
				},
			})
			require("telescope").load_extension("frecency")
			require("telescope").load_extension("file_browser")
			require("telescope").load_extension("zf-native")
			local themes = require("telescope.themes")
			vim.api.nvim_create_user_command("Recent", function()
				local Path = require("plenary.path")
				local os_home = vim.loop.os_homedir()
				require("telescope").extensions.frecency.frecency(themes.get_ivy({
					path_display = function(_, filename)
						if
							vim.startswith(filename, os_home --[[@as string]])
						then
							filename = "~/" .. Path:new(filename):make_relative(os_home)
						end
						return filename
					end,
					sorter = require("telescope.config").values.file_sorter(),
					layout_config = {
						height = 0.5,
					},
					previewer = false,
				}))
			end, {})
		end,
	},
	"nvim-telescope/telescope-frecency.nvim",
	{ "https://github.com/nvim-telescope/telescope-live-grep-args.nvim" },
	"https://github.com/nvim-telescope/telescope-file-browser.nvim",
	"https://github.com/natecraddock/telescope-zf-native.nvim",
	{
		"lervag/vimtex",
		config = function()
			vim.g.vimtex_view_method = "sioyek"
			vim.g.vimtex_view_sioyek_exe = "/Applications/sioyek.app/Contents/MacOS/sioyek"
		end,
	},
	{
		"https://github.com/MrcJkb/haskell-tools.nvim",
		version = "^3",
		ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
		config = function()
			local ht = require("haskell-tools")
			vim.g.haskell_tools = {
				tools = {
					hover = {
						enable = false,
					},
				},
				hls = {
					filetypes = { "haskell", "lhaskell", "cabal" },
					on_attach = function(_client, bufnr)
						local opts = vim.tbl_extend("keep", { noremap = true, silent = true }, { buffer = bufnr })
						vim.keymap.set("n", "<leader>cll", vim.lsp.codelens.run, opts)
						vim.keymap.set("n", "<leader>hs", ht.hoogle.hoogle_signature, opts)
					end,
					settings = {
						haskell = {
							plugin = {
								stan = {
									globalOn = false,
								},
							},
						},
					},
				},
			}
		end,
	},
	"https://github.com/itchyny/vim-haskell-indent",
	"https://github.com/Nymphium/vim-koka",
	"https://github.com/vim-scripts/alex.vim",
	"https://github.com/wlangstroth/vim-racket",
	"https://github.com/jaawerth/fennel.vim",
	{
		"https://github.com/L3MON4D3/LuaSnip",
		config = function()
			vim.cmd([[
      " press <Tab> to expand or jump in a snippet. These can also be mapped separately
      " via <Plug>luasnip-expand-snippet and <Plug>luasnip-jump-next.
      imap <silent><expr> <Tab> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>'
      inoremap <silent> <S-Tab> <cmd>lua require'luasnip'.jump(-1)<Cr>
      snoremap <silent> <Tab> <cmd>lua require('luasnip').jump(1)<Cr>
      snoremap <silent> <S-Tab> <cmd>lua require('luasnip').jump(-1)<Cr>
      " For changing choices in choiceNodes (not strictly necessary for a basic setup).
      imap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
      smap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
      ]])
			require("luasnip.loaders.from_snipmate").lazy_load()
		end,
	},
	{
		"nvim-tree/nvim-web-devicons",
		event = "VeryLazy",
		opts = {
			override_by_extension = {
				["v"] = {
					icon = "",
					color = "#dba25c",
					name = "Coq",
				},
			},
		},
	},
	"kevinhwang91/promise-async",
	"https://github.com/hrsh7th/cmp-buffer",
{
    "https://github.com/stevearc/oil.nvim",
    init = function()
        vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })
    end,
    config = function()
        require("oil").setup({
            view_options = {
                -- Show files and directories that start with "."
                show_hidden = true,
                -- This function defines what is considered a "hidden" file
                is_hidden_file = function(name, bufnr)
                    return vim.startswith(name, ".")
                end,
            }
        })
    end
},  "https://github.com/tpope/vim-characterize",
	{
		"https://github.com/junegunn/vim-easy-align",
		config = function()
			vim.cmd([[nmap ga <Plug>(EasyAlign)]])
		end,
	},
	{ "ruifm/gitlinker.nvim", config = true },
	"kaarmu/typst.vim",
	{
		"chomosuke/typst-preview.nvim",
		ft = "typst",
		version = "0.3.*",
		build = function()
			require("typst-preview").update()
		end,
	},
	"https://github.com/dhruvasagar/vim-table-mode",
	{
		"https://github.com/smjonas/inc-rename.nvim",
		lazy = false,
		config = function()
			require("inc_rename").setup()
			vim.keymap.set("n", "<leader>rn", function()
				return ":IncRename " .. vim.fn.expand("<cword>")
			end, { expr = true })
		end,
	},
	"https://github.com/ii14/neorepl.nvim",
	{
		"https://github.com/bfredl/nvim-miniyank",
		config = function()
			vim.cmd([[
        augroup highlight_yank
          autocmd!
          autocmd TextYankPost * silent! lua vim.highlight.on_yank()
        augroup END
      ]])
			vim.cmd([[
        map p <Plug>(miniyank-autoput)
        map P <Plug>(miniyank-autoPut)
        map <leader>n <Plug>(miniyank-cycle)
        map <leader>N <Plug>(miniyank-cycleback)
        map <Leader><Space>c <Plug>(miniyank-tochar)
        map <Leader><Space>l <Plug>(miniyank-toline)
        map <Leader><Space>b <Plug>(miniyank-toblock)
      ]])
		end,
	},
	{
		"Olical/conjure",
		config = function()
			vim.g["conjure#mapping#prefix"] = "<Leader>"
		end,
	},
	{ "moll/vim-bbye" },
	"rhysd/conflict-marker.vim",
	{
		"https://github.com/chrisgrieser/nvim-spider",
		config = function()
			vim.keymap.set({ "n", "o", "x" }, "w", "<cmd>lua require('spider').motion('w')<CR>", { desc = "Spider-w" })
			vim.keymap.set({ "n", "o", "x" }, "e", "<cmd>lua require('spider').motion('e')<CR>", { desc = "Spider-e" })
			vim.keymap.set({ "n", "o", "x" }, "b", "<cmd>lua require('spider').motion('b')<CR>", { desc = "Spider-b" })
			vim.keymap.set(
				{ "n", "o", "x" },
				"ge",
				"<cmd>lua require('spider').motion('ge')<CR>",
				{ desc = "Spider-ge" }
			)
		end,
	},
	"wakatime/vim-wakatime",
	{
		"anuvyklack/hydra.nvim",
		config = function()
			local Hydra = require("hydra")
			Hydra({
				name = "Side scroll",
				mode = "n",
				body = "z",
				heads = {
					{ "h", "5zh" },
					{ "l", "5zl", { desc = "←/→" } },
					{ "H", "zH" },
					{ "L", "zL", { desc = "half screen ←/→" } },
				},
			})
		end,
	},
	"https://github.com/tpope/vim-eunuch",
	{
		"chrisgrieser/nvim-early-retirement",
		config = true,
		event = "VeryLazy",
	},
	"rstacruz/vim-closer",
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { { "prettierd", "prettier" } },
				javascriptreact = { { "prettierd", "prettier" } },
				typescript = { { "prettierd", "prettier" } },
				typescriptreact = { { "prettierd", "prettier" } },
				python = { "black" },
			},
			formatters = {
				black = {
					command = "/Users/timothy/Lang/Venv3.11/bin/black",
				},
			},
		},
	},
	{
		"https://github.com/neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			require("neodev").setup({})
			require("lspconfig")["lua_ls"].setup({
				settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
						},
						diagnostics = {
							globals = {
								"vim",
								"require",
							},
							unusedLocalExclude = { "_*" },
						},
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
						},
						telemetry = {
							enable = false,
						},
					},
				},
			})
			require("lspconfig")["racket_langserver"].setup({})
			require("lspconfig")["ocamllsp"].setup({})
			require("lspconfig")["clangd"].setup({})
			require("lspconfig")["tsserver"].setup({})
			require("lspconfig").tailwindcss.setup({})
			require("lspconfig")["pyright"].setup({})
			require("lspconfig")["gopls"].setup({})
			require("lspconfig")["cssls"].setup({
				capabilities = capabilities,
			})
			require("lspconfig").jdtls.setup({})
			require("lspconfig")["typst_lsp"].setup({
				settings = {
					exportPdf = "onSave",
				},
			})
		end,
	},
	{ "https://github.com/github/copilot.vim" },
{
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = {
      show_help = "yes", -- Show help text for CopilotChatInPlace, default: yes
      debug = false, -- Enable or disable debug mode, the log file will be in ~/.local/state/nvim/CopilotChat.nvim.log
      disable_extra_info = 'no', -- Disable extra information (e.g: system prompt) in the response.
      language = "English" -- Copilot answer language settings when using default prompts. Default language is English.
      -- proxy = "socks5://127.0.0.1:3000", -- Proxies requests via https or socks.
      -- temperature = 0.1,
    },
    build = function()
      vim.notify("Please update the remote plugins by running ':UpdateRemotePlugins', then restart Neovim.")
    end,
    event = "VeryLazy",
    keys = {
      { "<leader>ccb", ":CopilotChatBuffer ", desc = "CopilotChat - Chat with current buffer" },
      { "<leader>cce", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
      { "<leader>cct", "<cmd>CopilotChatTests<cr>", desc = "CopilotChat - Generate tests" },
      {
        "<leader>ccT",
        "<cmd>CopilotChatVsplitToggle<cr>",
        desc = "CopilotChat - Toggle Vsplit", -- Toggle vertical split
      },
      {
        "<leader>ccv",
        ":CopilotChatVisual ",
        mode = "x",
        desc = "CopilotChat - Open in vertical split",
      },
      {
        "<leader>ccx",
        ":CopilotChatInPlace<cr>",
        mode = "x",
        desc = "CopilotChat - Run in-place code",
      },
      {
        "<leader>ccf",
        "<cmd>CopilotChatFixDiagnostic<cr>", -- Get a fix for the diagnostic message under the cursor.
        desc = "CopilotChat - Fix diagnostic",
      },
      {
        "<leader>ccr",
        "<cmd>CopilotChatReset<cr>", -- Reset chat history and clear buffer.
        desc = "CopilotChat - Reset chat history and clear buffer",
      }
    },
  },
	{
		"https://github.com/whonore/Coqtail",
		lazy = false,
		config = function()
			-- vscoq
			vim.g.loaded_coqtail = 1
			vim.g["coqtail#supported"] = 0

			-- NOTE: comment out to use VsCoq
			--
			-- vim.g.coqtail_nomap = 1
			-- vim.keymap.set({ "n", "i" }, "<C-c><C-l>", "<Plug>CoqToLine")
			-- vim.keymap.set({ "n", "i" }, "<C-c><C-j>", "<Plug>CoqNext")
			-- vim.keymap.set({ "n", "i" }, "<C-c><C-k>", "<Plug>CoqUndo")
			-- vim.keymap.set({ "n", "i" }, "<C-c><C-g>", "<Plug>CoqJumpToEnd")
		end,
	},
{
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function()
    return {
      sections = {
        lualine_c = {
          {
            'filename',
            path = 1  -- Use 2 for absolute path, 1 for relative path
          }
        }
      }
    }
  end,
},
{
		"tomtomjhj/vscoq.nvim",
		lazy = false,
		config = function()
			require("vscoq").setup({
				vscoq = {
					proof = {
						mode = 0, -- manual
					},
				},
			})
			vim.keymap.set({ "n", "i" }, "<C-c><C-l>", "<Cmd>VsCoq interpretToPoint<CR>")
			vim.keymap.set({ "n", "i" }, "<C-c><C-j>", "<Cmd>VsCoq stepForward<CR>")
			vim.keymap.set({ "n", "i" }, "<C-c><C-k>", "<Cmd>VsCoq stepBackward<CR>")
			vim.keymap.set({ "n", "i" }, "<C-c><C-e>", "<Cmd>VsCoq interpretToEnd<CR>")
			vim.keymap.set({ "n", "i" }, "<C-c><C-g>", "<Cmd>VsCoq jumpToEnd<CR>")
		end,
	},
	{ "https://github.com/pbrisbin/vim-colors-off" },
	-- {
	--   "https://github.com/ludovicchabant/vim-gutentags",
	--   filetypes = { 'coq' },
	--   config = function()
	--     vim.g.gutentags_ctags_executable = '/opt/homebrew/bin/ctags'
	--     vim.g.gutentags_gtags_options_file = 'coq.ctags'
	--     vim.g.gutentags_add_default_project_roots = 0
	--     vim.g.gutentags_generate_on_missing = 0
	--     vim.g.gutentags_generate_on_new = 0
	--     vim.g.gutentags_generate_on_write = 0
	--   end,
	--   cmd = "GutentagsUpdate"
	-- },
	{ "folke/neodev.nvim", opts = {} },
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
	--	opts = {
	--		-- NOTWORKING
	--		triggers_nowait = {
	--			"<leader>",
	--		},
	--	},
	},
	-- {
	-- 	"lukas-reineke/indent-blankline.nvim",
	-- 	main = "ibl",
	-- 	-- NOTE: VeryLazy seems to load ibl after colorscheme,
	-- 	-- so IBLIndent and IBLScope highlights are applied
	-- 	event = "VeryLazy",
	-- 	config = function()
	-- 		require("ibl").setup({
	-- 			indent = {
	-- 				char = "│",
	-- 				smart_indent_cap = true,
	-- 			},
	-- 			scope = {
	-- 				show_start = false,
	-- 				show_end = false,
	-- 			},
	-- 		})
	-- 		-- HACK: hide indent lines in visual mode
	-- 		-- ref: https://github.com/lukas-reineke/indent-blankline.nvim/issues/132#issuecomment-1781195298
	-- 		local ibl_visual_hide = vim.api.nvim_create_augroup("ibl_visual_hide", { clear = true })
	-- 		vim.api.nvim_create_autocmd("ModeChanged", {
	-- 			group = ibl_visual_hide,
	-- 			pattern = "[vV\x16]*:*", -- visual → anything
	-- 			command = "IBLEnable",
	-- 			desc = "Enable IBL in non-Visual mode",
	-- 		})
	-- 		vim.api.nvim_create_autocmd("ModeChanged", {
	-- 			group = ibl_visual_hide,
	-- 			pattern = "*:[vV\x16]*", -- anything → visual
	-- 			command = "IBLDisable",
	-- 			desc = "Disable IBL in Visual mode",
	-- 		})
	-- 	end,
	-- },
	{ "https://github.com/folke/tokyonight.nvim" },
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
	{
		-- NOTE: taken from nvchad
		"nvim-tree/nvim-tree.lua",
		opts = {
			diagnostics = {
				enable = true,
			},
			disable_netrw = true,
			hijack_netrw = true,
			hijack_cursor = true,
			hijack_unnamed_buffer_when_opening = false,
			sync_root_with_cwd = true,
			update_focused_file = {
				enable = true,
				update_root = false,
			},
			view = {
				adaptive_size = false,
				side = "left",
				width = 30,
				preserve_window_proportions = true,
			},
			git = {
				enable = false,
				ignore = true,
			},
			filesystem_watchers = {
				enable = true,
			},
			actions = {
				open_file = {
					resize_window = true,
				},
			},
			renderer = {
				root_folder_label = false,
				highlight_git = false,
				highlight_opened_files = "none",

				indent_markers = {
					enable = false,
				},

				icons = {
					show = {
						file = true,
						folder = true,
						folder_arrow = true,
						git = false,
					},

					glyphs = {
						default = "󰈚",
						symlink = "",
						folder = {
							default = "",
							empty = "",
							empty_open = "",
							open = "",
							symlink = "",
							symlink_open = "",
							arrow_open = "",
							arrow_closed = "",
						},
						git = {
							unstaged = "✗",
							staged = "✓",
							unmerged = "",
							renamed = "➜",
							untracked = "★",
							deleted = "",
							ignored = "◌",
						},
					},
				},
			},
		},
	},
	{
		"Julian/lean.nvim",
		event = { "BufReadPre *.lean", "BufNewFile *.lean" },

		dependencies = {
			"neovim/nvim-lspconfig",
			"nvim-lua/plenary.nvim",
			"hrsh7th/nvim-cmp",
		},

		opts = {
			mappings = true,
		},
	},
	{
		"phha/zenburn.nvim",
		config = function()
			require("zenburn").setup()
		end,
	},
	{ "https://github.com/pocco81/true-zen.nvim", opts = true },
	{
		"glacambre/firenvim",

		-- Lazy load firenvim
		-- Explanation: https://github.com/folke/lazy.nvim/discussions/463#discussioncomment-4819297
		lazy = not vim.g.started_by_firenvim,
		build = function()
			vim.fn["firenvim#install"](0)
		end,
    config = function ()
      vim.g.firenvim_config.localSettings['.*'] = { takeover = 'never' }
    end,
	},
}, {
	install = {
		colorscheme = { "rose-pine" },
	},
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"netrwPlugin",
				"spellfile",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})

vim.opt.cmdheight = 1
vim.opt.laststatus = 3

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.undofile = true

vim.cmd([[set ts=2 sw=2 sts=2 et]])

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrap = false

vim.o.completeopt = "menuone,noinsert,noselect"
vim.o.shortmess = vim.o.shortmess .. "c"
vim.opt.showmode = false

-- NOTE: ref: https://gist.github.com/romainl/1cad2606f7b00088dda3bb511af50d53
vim.cmd([[
command! -range=% SP <line1>,<line2>w !curl -F 'sprunge=<-' http://sprunge.us | tr -d '\n' | pbcopy
command! -range=% CL <line1>,<line2>w !curl -F 'clbin=<-' https://clbin.com | tr -d '\n' | pbcopy
command! -range=% VP <line1>,<line2>w !curl -F 'text=<-' http://vpaste.net | tr -d '\n' | pbcopy
command! -range=% EN <line1>,<line2>w !curl -F 'file=@-;' https://envs.sh | tr -d '\n' | pbcopy

]])
vim.o.clipboard = 'unnamed'

vim.cmd([[set formatoptions-=cro]])

vim.cmd([[
nn <Leader>s<Right> <cmd>ISwapNodeWithRight<CR>
nn <Leader>s<Left> <cmd>ISwapNodeWithLeft<CR>
nn <Leader>ss <cmd>ISwap<CR>
]])

vim.keymap.set("n", "<leader>cd", ":lcd %:h<CR>")

vim.cmd([[
function! FollowSymlink()
  let fname = resolve(expand('%:p'))
  bwipeout
  exec "edit " . fname
endfunction
command FollowSymlink call FollowSymlink()
]])

if vim.g.neovide then
	vim.g.neovide_input_macos_option_key_is_meta = "both"
	vim.opt.linespace = 5
	vim.opt.guifont = { "JetBrains Mono", "JetBrainsMono Nerd Font", ":h18" }

	vim.g.neovide_floating_shadow = true
	vim.g.neovide_floating_z_height = 5
	vim.g.neovide_light_angle_degrees = 45
	vim.g.neovide_light_radius = 60

	vim.g.neovide_cursor_vfx_mode = "railgun"
	vim.g.neovide_cursor_vfx_particle_lifetime = 1.5
	vim.g.neovide_cursor_vfx_particle_density = 17.0
	vim.g.neovide_cursor_vfx_particle_phase = 4.5
	vim.g.neovide_cursor_vfx_particle_curl = 4.0

	vim.keymap.set({ "n", "v" }, "<C-+>", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>")
	vim.keymap.set({ "n", "v" }, "<C-->", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>")
	vim.keymap.set({ "n", "v" }, "<C-0>", ":lua vim.g.neovide_scale_factor = 1<CR>")
end

vim.opt.cursorline = true

vim.keymap.set({ "n", "v" }, "<leader>f<space>", function()
	require("conform").format({ async = true, lsp_fallback = true })
end, { noremap = true, silent = true })

vim.opt.statusline = "   %F"
vim.opt.conceallevel = 2
vim.opt.concealcursor = "nc"
vim.opt.number = true

-- NOTE: refresh devicons to render correctly whether light or dark
vim.api.nvim_create_autocmd({ "VimEnter" }, {
	callback = function()
		require("nvim-web-devicons").refresh()
	end,
})

vim.g.loaded_perl_provider = 0
